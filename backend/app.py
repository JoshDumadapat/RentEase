"""
ID Validation Backend Service
Uses InsightFace for face comparison, Tesseract OCR for text extraction, and fuzzywuzzy for text matching
Also includes AI Chat functionality using OpenAI API
"""
from flask import Flask, request, jsonify
from flask_cors import CORS
import cv2
import numpy as np
import insightface
from PIL import Image
import pytesseract
from fuzzywuzzy import fuzz
import base64
import io
import os
try:
    import openai
    OPENAI_AVAILABLE = True
except ImportError:
    OPENAI_AVAILABLE = False
    # print("⚠️  OpenAI library not installed. Install with: pip install openai")
from typing import List, Dict, Optional

app = Flask(__name__)
CORS(app)  # Enable CORS for Flutter app

# Initialize OpenAI client (optional - will use if API key is set)
openai_api_key = os.environ.get('OPENAI_API_KEY')
openai_client = None
if OPENAI_AVAILABLE and openai_api_key:
    try:
        openai_client = openai.OpenAI(api_key=openai_api_key)
        # print("✅ OpenAI API key loaded successfully!")
    except Exception as e:
        # print(f"⚠️  Error initializing OpenAI: {e}")
        openai_client = None
elif not OPENAI_AVAILABLE:
    # print("⚠️  OpenAI library not installed. AI chat will use fallback responses.")
else:
    # print("⚠️  OpenAI API key not found. AI chat will use fallback responses.")

# Initialize InsightFace model (CORRECT SETUP)
# print("Loading InsightFace model...")
face_model = insightface.app.FaceAnalysis(
    name="buffalo_l",  # Use buffalo_l model
    providers=['CPUExecutionProvider']  # or ['CUDAExecutionProvider'] if GPU available
)
face_model.prepare(ctx_id=0, det_size=(640, 640))
# print("InsightFace model loaded successfully!")

# Configure Tesseract path (update if needed)
# For Windows: pytesseract.pytesseract.tesseract_cmd = r'C:\Program Files\Tesseract-OCR\tesseract.exe'
# For Linux/Mac: Usually already in PATH

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({'status': 'ok', 'message': 'ID Validation Service is running'})

@app.route('/ai/chat', methods=['POST'])
def ai_chat():
    """
    AI Chat endpoint for Subspace AI assistant
    Expects: {
        "message": "user message",
        "conversationHistory": [
            {"role": "user", "content": "..."},
            {"role": "assistant", "content": "..."}
        ],
        "userId": "optional user id for personalization"
    }
    Returns: {
        "response": "AI response text",
        "error": null or error message
    }
    """
    try:
        data = request.json
        if not data or 'message' not in data:
            return jsonify({'error': 'Message is required'}), 400
        
        user_message = data['message'].strip()
        if not user_message:
            return jsonify({'error': 'Message cannot be empty'}), 400
        
        conversation_history = data.get('conversationHistory', [])
        user_id = data.get('userId')
        
        # Enhanced system prompt for Subspace AI
        system_prompt = """You are Subspace, an intelligent AI assistant for RentEase, a property rental platform.

YOUR EXPERTISE:
- Property Types: Apartments, Rooms, Condos, Houses, Dorms, Boarding Houses, Studios
- Rental Details: Monthly rent, Security deposit, Advance payment, Bedrooms, Bathrooms, Floor area, Location, Availability
- Amenities: Electricity, Water, Internet/WiFi, Laundry, Parking, Security, Aircon, Pet-friendly, Kitchen access, Private/Shared CR, Furnished/Unfurnished
- Math Skills: Calculate rental costs, monthly payments, deposits, total first payments, percentages, basic arithmetic (addition, subtraction, multiplication, division)

YOUR CAPABILITIES:
- Help users find rental properties matching budget, location, and preferences
- Calculate rental costs accurately (rent + deposit = total first payment, etc.)
- Explain property listings, amenities, and rental terms
- Provide practical rental advice and tips
- Answer questions about RentEase platform features
- Understand context from conversation history

RESPONSE STYLE:
- Be friendly, professional, and CONCISE (50-120 words max)
- For math: Show clear calculations and results
- For properties: Guide users to search feature for specific listings
- Be helpful, accurate, and actionable
- Use natural, conversational language
- If unsure, ask clarifying questions

IMPORTANT: Keep responses SHORT, DIRECT, and USEFUL. No fluff."""
        
        # Build conversation messages for OpenAI
        messages = [{"role": "system", "content": system_prompt}]
        
        # Add conversation history (limit to last 10 messages to avoid token limits)
        for msg in conversation_history[-10:]:
            role = msg.get('role', 'user')
            content = msg.get('content', '')
            if role in ['user', 'assistant'] and content:
                messages.append({"role": role, "content": content})
        
        # Add current user message
        messages.append({"role": "user", "content": user_message})
        
        # Call OpenAI API if available (with optimized timeout and settings)
        if openai_client:
            try:
                response = openai_client.chat.completions.create(
                    model="gpt-3.5-turbo",
                    messages=messages,
                    temperature=0.7,
                    max_tokens=150,  # Further reduced for faster responses
                    timeout=8.0,  # Reduced timeout to 8 seconds
                )
                ai_response = response.choices[0].message.content.strip()
                if ai_response:
                    return jsonify({
                        'response': ai_response,
                        'error': None
                    }), 200
            except Exception:
                # Fall through to fallback response on timeout or error
                pass
        
        # Fallback response if OpenAI is not available
        fallback_response = _generate_fallback_response(user_message)
        return jsonify({
            'response': fallback_response,
            'error': None,
            'note': 'Using fallback response (OpenAI not configured)'
        }), 200
        
    except Exception as e:
        import traceback
        # print(f"AI Chat error: {e}")
        # print(traceback.format_exc())
        return jsonify({
            'response': "I'm sorry, I encountered an error. Please try again.",
            'error': str(e)
        }), 500

def _generate_fallback_response(user_message: str) -> str:
    """Generate intelligent fallback response with enhanced listing knowledge and math"""
    import re
    message_lower = user_message.lower().strip()
    
    # Enhanced math calculations - supports decimals
    math_patterns = [
        (r'(\d+\.?\d*)\s*\+\s*(\d+\.?\d*)', lambda m: float(m.group(1)) + float(m.group(2))),
        (r'(\d+\.?\d*)\s*-\s*(\d+\.?\d*)', lambda m: float(m.group(1)) - float(m.group(2))),
        (r'(\d+\.?\d*)\s*\*\s*(\d+\.?\d*)', lambda m: float(m.group(1)) * float(m.group(2))),
        (r'(\d+\.?\d*)\s*/\s*(\d+\.?\d*)', lambda m: float(m.group(1)) / float(m.group(2)) if float(m.group(2)) != 0 else None),
        (r'(\d+\.?\d*)\s*%\s*of\s*(\d+\.?\d*)', lambda m: float(m.group(1)) * float(m.group(2)) / 100),
    ]
    
    # Check for math questions
    for pattern, func in math_patterns:
        match = re.search(pattern, user_message, re.IGNORECASE)
        if match:
            try:
                result = func(match)
                if result is None:
                    return "Cannot divide by zero."
                if result % 1 == 0:
                    return f"The answer is {int(result)}."
                else:
                    return f"The answer is {result:.2f}."
            except:
                pass
    
    # Enhanced rental cost calculations - Yearly/Annual calculations
    if any(word in message_lower for word in ['year', 'annual', 'per year']) and any(word in message_lower for word in ['how much', 'cost', 'spend', 'rent']):
        numbers = re.findall(r'\d+', user_message)
        if numbers:
            try:
                monthly_rent = float(numbers[0])
                yearly_cost = monthly_rent * 12
                return f"If the monthly rent is ₱{monthly_rent:,.0f}, you'll spend ₱{yearly_cost:,.0f} per year (₱{monthly_rent:,.0f} × 12 months)."
            except:
                pass
    
    # Monthly calculations
    if 'month' in message_lower and any(word in message_lower for word in ['how much', 'cost']):
        numbers = re.findall(r'\d+', user_message)
        if len(numbers) >= 2:
            try:
                total = float(numbers[0])
                months = float(numbers[1])
                monthly = total / months
                return f"If you spend ₱{total:,.0f} over {int(months)} months, that's ₱{monthly:,.0f} per month."
            except:
                pass
    
    # Enhanced rental cost calculations - First payment (rent + deposit)
    if any(word in message_lower for word in ['calculate', 'total', 'deposit', 'advance', 'first payment']):
        numbers = re.findall(r'\d+', user_message)
        if len(numbers) >= 2:
            try:
                rent = float(numbers[0])
                deposit = float(numbers[1])
                total = rent + deposit
                return f"Monthly rent: ₱{rent:,.0f}\nDeposit: ₱{deposit:,.0f}\nTotal first payment: ₱{total:,.0f}"
            except:
                pass
        elif len(numbers) == 1:
            return f"For ₱{numbers[0]}, you can find good rental options. Use search filters to browse properties in this price range."
    
    # Rental cost questions with numbers - smarter detection
    if any(word in message_lower for word in ['how much', 'cost', 'spend']) and 'rent' in message_lower:
        numbers = re.findall(r'\d+', user_message)
        if numbers:
            try:
                monthly_rent = float(numbers[0])
                if 'year' in message_lower or 'annual' in message_lower:
                    yearly_cost = monthly_rent * 12
                    return f"If the monthly rent is ₱{monthly_rent:,.0f}, you'll spend ₱{yearly_cost:,.0f} per year (₱{monthly_rent:,.0f} × 12 months)."
                elif 'month' in message_lower and len(numbers) >= 2:
                    months = float(numbers[1])
                    total = monthly_rent * months
                    return f"If the monthly rent is ₱{monthly_rent:,.0f}, you'll spend ₱{total:,.0f} over {int(months)} months."
                else:
                    yearly_cost = monthly_rent * 12
                    return f"For ₱{monthly_rent:,.0f} monthly rent, that's ₱{yearly_cost:,.0f} per year. Use search filters to find properties in this price range."
            except:
                pass
    
    # Enhanced greetings
    if any(word in message_lower for word in ['hello', 'hi', 'hey', 'greetings', 'good morning', 'good afternoon', 'good evening']):
        return "Hello! I'm Subspace, your AI assistant for RentEase. I can help you find rental properties, calculate costs, and answer questions. How can I assist you today?"
    
    # Property types with context
    property_keywords = {
        'apartment': 'apartments',
        'room': 'rooms',
        'condo': 'condos',
        'house': 'houses',
        'dorm': 'dorms',
        'boarding': 'boarding houses',
        'studio': 'studios'
    }
    for key, value in property_keywords.items():
        if key in message_lower:
            return f"I can help you find {value}! Use the search feature to browse listings. What's your budget and preferred location?"
    
    # Price/Budget with smarter responses (only if not already handled by calculation logic)
    if (any(word in message_lower for word in ['price', 'cost', 'rent', 'budget', 'cheap', 'expensive', 'affordable']) and
        'how much' not in message_lower and
        'calculate' not in message_lower and
        'year' not in message_lower and
        'month' not in message_lower):
        numbers = re.findall(r'\d+', user_message)
        if numbers:
            return f"For ₱{numbers[0]}, you can find good options! Use search filters to find properties in your budget range. Prices vary by location, size, and amenities."
        return "Rental prices vary by location and property type. Use search filters to find properties within your budget. What's your price range?"
    
    # Location with more helpful info
    if any(word in message_lower for word in ['location', 'where', 'area', 'address', 'near', 'place']):
        return "Search by location using the search feature. The app shows properties on a map with filters. What area or landmark are you interested in?"
    
    # Enhanced amenities
    if any(word in message_lower for word in ['amenity', 'amenities', 'wifi', 'parking', 'aircon', 'kitchen', 'laundry', 'security', 'furnished']):
        return "Common amenities include: WiFi, Parking, Aircon, Kitchen, Laundry, Security, Furnished options. Use search filters to find properties with specific amenities you need."
    
    # Help with specific guidance
    if any(word in message_lower for word in ['help', 'how', 'what can you', 'what do you', 'guide', 'assist']):
        return "I help with:\n• Finding rental properties\n• Calculating rental costs\n• Understanding listings\n• Rental advice\n\nWhat do you need help with?"
    
    # Thanks
    if any(word in message_lower for word in ['thank', 'thanks']):
        return "You're welcome! Feel free to ask anytime for help with rentals or RentEase."
    
    # Questions about RentEase
    if any(word in message_lower for word in ['rentease', 'app', 'platform']):
        return "RentEase is a property rental platform. You can search for apartments, rooms, condos, houses, dorms, and boarding houses. Use the search feature to find properties that match your needs!"
    
    # Default
    return "I can help you find rental properties, calculate costs, or answer questions about RentEase. What would you like to know?"

@app.route('/extract-text', methods=['POST'])
def extract_text():
    """
    Extract text from ID image using Tesseract OCR
    Expects: { "image": "base64_encoded_image" }
    Returns: { "fullName": "...", "idNumber": "...", "dateOfBirth": "...", "rawText": "..." }
    """
    try:
        data = request.json
        if not data or 'image' not in data:
            return jsonify({'error': 'No image provided'}), 400
        
        # Decode base64 image
        image_data = base64.b64decode(data['image'])
        image = Image.open(io.BytesIO(image_data))
        
        # Convert to RGB if needed
        if image.mode != 'RGB':
            image = image.convert('RGB')
        
        # Perform OCR
        raw_text = pytesseract.image_to_string(image, lang='eng')
        
        # Extract structured data
        extracted_data = {
            'rawText': raw_text,
            'fullName': extract_name(raw_text),
            'idNumber': extract_id_number(raw_text),
            'dateOfBirth': extract_date_of_birth(raw_text)
        }
        
        return jsonify(extracted_data), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/compare-face', methods=['POST'])
def compare_face():
    """
    Compare faces from ID and selfie using InsightFace (CORRECT IMPLEMENTATION - Multipart Files)
    Accepts: multipart/form-data with 'id_image' and 'selfie_image' files
    Returns: { "similarity": 0.0-1.0, "match": true/false, "message": "..." }
    """
    try:
        # Check if files are present
        if 'id_image' not in request.files or 'selfie_image' not in request.files:
            return jsonify({
                'similarity': 0.0,
                'match': False,
                'message': 'Both ID and selfie images required'
            }), 400
        
        id_file = request.files['id_image']
        selfie_file = request.files['selfie_image']
        
        if id_file.filename == '' or selfie_file.filename == '':
            return jsonify({
                'similarity': 0.0,
                'match': False,
                'message': 'Empty files provided'
            }), 400
        
        # Load images from files
        id_img = Image.open(io.BytesIO(id_file.read())).convert("RGB")
        selfie_img = Image.open(io.BytesIO(selfie_file.read())).convert("RGB")
        
        # Convert PIL to OpenCV format
        id_cv = cv2.cvtColor(np.array(id_img), cv2.COLOR_RGB2BGR)
        selfie_cv = cv2.cvtColor(np.array(selfie_img), cv2.COLOR_RGB2BGR)
        
        # Extract exactly one face from each image (CRITICAL)
        id_faces = face_model.get(id_cv)
        selfie_faces = face_model.get(selfie_cv)
        
        # Enforce exactly one face per image
        if len(id_faces) == 0:
            return jsonify({
                'similarity': 0.0,
                'match': False,
                'message': 'No face detected in ID image'
            }), 200
        
        if len(id_faces) > 1:
            return jsonify({
                'similarity': 0.0,
                'match': False,
                'message': f'Multiple faces detected in ID image ({len(id_faces)}) - must be exactly one'
            }), 200
        
        if len(selfie_faces) == 0:
            return jsonify({
                'similarity': 0.0,
                'match': False,
                'message': 'No face detected in selfie image'
            }), 200
        
        if len(selfie_faces) > 1:
            return jsonify({
                'similarity': 0.0,
                'match': False,
                'message': f'Multiple faces detected in selfie ({len(selfie_faces)}) - must be exactly one'
            }), 200
        
        # Get the single face from each image
        id_face = id_faces[0]
        selfie_face = selfie_faces[0]
        
        # Check face quality (detection score)
        if id_face.det_score < 0.6:
            return jsonify({
                'similarity': 0.0,
                'match': False,
                'message': f'Low-quality face in ID image (score: {id_face.det_score:.2f}, required: ≥0.6)'
            }), 200
        
        if selfie_face.det_score < 0.6:
            return jsonify({
                'similarity': 0.0,
                'match': False,
                'message': f'Low-quality face in selfie (score: {selfie_face.det_score:.2f}, required: ≥0.6)'
            }), 200
        
        # Check face size (bounding box width)
        id_bbox = id_face.bbox
        selfie_bbox = selfie_face.bbox
        id_face_width = id_bbox[2] - id_bbox[0]
        selfie_face_width = selfie_bbox[2] - selfie_bbox[0]
        
        if id_face_width < 100:
            return jsonify({
                'similarity': 0.0,
                'match': False,
                'message': f'ID face too small (width: {id_face_width:.0f}px, required: ≥100px)'
            }), 200
        
        if selfie_face_width < 100:
            return jsonify({
                'similarity': 0.0,
                'match': False,
                'message': f'Selfie face too small (width: {selfie_face_width:.0f}px, required: ≥100px)'
            }), 200
        
        # Get NORMED embeddings (CRITICAL - must use normed_embedding)
        id_embedding = id_face.normed_embedding
        selfie_embedding = selfie_face.normed_embedding
        
        # Calculate cosine similarity (dot product = cosine similarity when embeddings are normalized)
        similarity = float(np.dot(id_embedding, selfie_embedding))
        
        # Validation rule: Similarity ≥ 0.12 → PASS (12% threshold)
        threshold = 0.12
        is_match = similarity >= threshold
        
        return jsonify({
            'similarity': float(similarity),
            'match': is_match,
            'message': f'Face match confirmed (similarity: {similarity:.3f})' if is_match else f'Face does not match (similarity: {similarity:.3f}, required: {threshold})'
        }), 200
        
    except Exception as e:
        import traceback
        return jsonify({
            'similarity': 0.0,
            'match': False,
            'message': f'Error: {str(e)}',
            'traceback': traceback.format_exc() if app.debug else None
        }), 500

@app.route('/compare-faces', methods=['POST'])
def compare_faces():
    """
    Compare faces from ID and selfie using InsightFace (base64 format - for backward compatibility)
    Expects: { "idImage": "base64_encoded_id_image", "selfieImage": "base64_encoded_selfie_image" }
    Returns: { "isMatch": true/false, "similarity": 0.0-1.0, "message": "..." }
    """
    try:
        data = request.json
        if not data or 'idImage' not in data or 'selfieImage' not in data:
            return jsonify({'error': 'Both ID and selfie images required'}), 400
        
        # Decode images
        id_image_data = base64.b64decode(data['idImage'])
        selfie_image_data = base64.b64decode(data['selfieImage'])
        
        # Convert to numpy arrays
        id_np = np.frombuffer(id_image_data, np.uint8)
        selfie_np = np.frombuffer(selfie_image_data, np.uint8)
        
        id_cv = cv2.imdecode(id_np, cv2.IMREAD_COLOR)
        selfie_cv = cv2.imdecode(selfie_np, cv2.IMREAD_COLOR)
        
        if id_cv is None or selfie_cv is None:
            return jsonify({'error': 'Failed to decode images'}), 400
        
        # Detect and extract face embeddings
        id_faces = face_model.get(id_cv)
        selfie_faces = face_model.get(selfie_cv)
        
        if len(id_faces) == 0:
            return jsonify({
                'isMatch': False,
                'confidence': 0.0,
                'message': 'No face detected in ID image'
            }), 200
        
        if len(selfie_faces) == 0:
            return jsonify({
                'isMatch': False,
                'confidence': 0.0,
                'message': 'No face detected in selfie'
            }), 200
        
        # Enforce exactly one face per image (CRITICAL)
        if len(id_faces) > 1:
            return jsonify({
                'isMatch': False,
                'confidence': 0.0,
                'similarity': 0.0,
                'message': 'Multiple faces detected in ID image - must be exactly one'
            }), 200
        
        if len(selfie_faces) > 1:
            return jsonify({
                'isMatch': False,
                'confidence': 0.0,
                'similarity': 0.0,
                'message': 'Multiple faces detected in selfie - must be exactly one'
            }), 200
        
        # Get the single face from each image
        id_face = id_faces[0]
        selfie_face = selfie_faces[0]
        
        # Check face quality (detection score)
        if id_face.det_score < 0.6:
            return jsonify({
                'isMatch': False,
                'confidence': 0.0,
                'similarity': 0.0,
                'message': 'Low-quality face detected in ID image'
            }), 200
        
        if selfie_face.det_score < 0.6:
            return jsonify({
                'isMatch': False,
                'confidence': 0.0,
                'similarity': 0.0,
                'message': 'Low-quality face detected in selfie'
            }), 200
        
        # Check face size (bounding box)
        id_bbox = id_face.bbox
        selfie_bbox = selfie_face.bbox
        id_face_width = id_bbox[2] - id_bbox[0]
        selfie_face_width = selfie_bbox[2] - selfie_bbox[0]
        
        if id_face_width < 100:
            return jsonify({
                'isMatch': False,
                'confidence': 0.0,
                'similarity': 0.0,
                'message': 'ID face too small'
            }), 200
        
        if selfie_face_width < 100:
            return jsonify({
                'isMatch': False,
                'confidence': 0.0,
                'similarity': 0.0,
                'message': 'Selfie face too small'
            }), 200
        
        # Get NORMED embeddings (CRITICAL - must use normed_embedding)
        id_embedding = id_face.normed_embedding
        selfie_embedding = selfie_face.normed_embedding
        
        # Calculate cosine similarity (dot product = cosine similarity when embeddings are normalized)
        similarity = float(np.dot(id_embedding, selfie_embedding))
        
        # Validation rule: Similarity ≥ 0.12 → PASS (12% threshold)
        threshold = 0.12
        is_match = similarity >= threshold
        
        return jsonify({
            'isMatch': is_match,
            'confidence': float(similarity),  # Use similarity as confidence
            'similarity': float(similarity),
            'message': 'Face match confirmed' if is_match else f'Face does not match (similarity: {similarity:.2f}, required: {threshold})'
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/validate-id', methods=['POST'])
def validate_id():
    """
    Complete ID validation endpoint
    Expects: {
        "idImage": "base64_encoded_id_image",
        "selfieImage": "base64_encoded_selfie_image",
        "userInputIdNumber": "...",
        "userInputFirstName": "...",
        "userInputLastName": "...",
        "userInputBirthday": "...",
        "userType": "student" or "professional"
    }
    Returns: Complete validation result
    """
    try:
        data = request.json
        
        # Step 1: Extract text from ID
        ocr_result = extract_text_internal(data.get('idImage'))
        if not ocr_result:
            return jsonify({
                'isValid': False,
                'errorMessage': 'Cannot validate your credentials.'
            }), 200
        
        # Step 2: Detect ID type
        id_type = detect_id_type(ocr_result['rawText'])
        is_government_id = id_type == 'government'
        
        # Step 3: Validate ID type requirement
        user_type = data.get('userType')
        if user_type == 'professional' and not is_government_id:
            return jsonify({
                'isValid': False,
                'idType': id_type,
                'isGovernmentId': False,
                'errorMessage': 'Cannot validate your credentials.'
            }), 200
        
        # Step 4: Validate text
        text_validation = validate_text(
            extracted_data=ocr_result,
            user_input_id_number=data.get('userInputIdNumber', ''),
            user_input_first_name=data.get('userInputFirstName', ''),
            user_input_last_name=data.get('userInputLastName', ''),
            user_input_birthday=data.get('userInputBirthday')
        )
        
        # Step 5: Compare faces
        face_match = compare_faces_internal(
            data.get('idImage'),
            data.get('selfieImage')
        )
        
        # Step 6: Final validation
        is_valid = text_validation['isValid'] and face_match['isMatch']
        
        return jsonify({
            'isValid': is_valid,
            'textValidation': text_validation,
            'faceMatch': face_match,
            'extractedData': ocr_result,
            'idType': id_type,
            'isGovernmentId': is_government_id,
            'errorMessage': None if is_valid else 'Cannot validate your credentials.'
        }), 200
        
    except Exception as e:
        return jsonify({
            'isValid': False,
            'errorMessage': 'Cannot validate your credentials.'
        }), 200

def extract_text_internal(image_base64):
    """Internal function to extract text from image with enhanced OCR for vertical text"""
    try:
        image_data = base64.b64decode(image_base64)
        image = Image.open(io.BytesIO(image_data))
        if image.mode != 'RGB':
            image = image.convert('RGB')
        
        # Convert PIL to OpenCV for preprocessing
        import numpy as np
        img_array = np.array(image)
        img_cv = cv2.cvtColor(img_array, cv2.COLOR_RGB2BGR)
        
        # PREPROCESSING FOR BETTER OCR (especially vertical text)
        # 1. Convert to grayscale
        gray = cv2.cvtColor(img_cv, cv2.COLOR_BGR2GRAY)
        
        # 2. Apply adaptive thresholding for better text contrast
        thresh = cv2.adaptiveThreshold(
            gray, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, 
            cv2.THRESH_BINARY, 11, 2
        )
        
        # 3. Apply morphological operations to clean up
        kernel = np.ones((2, 2), np.uint8)
        cleaned = cv2.morphologyEx(thresh, cv2.MORPH_CLOSE, kernel)
        
        # 4. Convert back to PIL for Tesseract
        processed_image = Image.fromarray(cleaned)
        
        # TRY MULTIPLE OCR CONFIGURATIONS FOR VERTICAL TEXT
        all_texts = []
        
        # Configuration 1: Default (horizontal text)
        config1 = '--oem 3 --psm 6'  # Uniform block of text
        text1 = pytesseract.image_to_string(processed_image, lang='eng', config=config1)
        if text1.strip():
            all_texts.append(text1)
        
        # Configuration 2: Single column (for vertical text)
        config2 = '--oem 3 --psm 4'  # Single column of text
        text2 = pytesseract.image_to_string(processed_image, lang='eng', config=config2)
        if text2.strip():
            all_texts.append(text2)
        
        # Configuration 3: Single line (for ID numbers)
        config3 = '--oem 3 --psm 7'  # Single line
        text3 = pytesseract.image_to_string(processed_image, lang='eng', config=config3)
        if text3.strip():
            all_texts.append(text3)
        
        # Configuration 4: Single word (for vertical digits)
        config4 = '--oem 3 --psm 8'  # Single word
        text4 = pytesseract.image_to_string(processed_image, lang='eng', config=config4)
        if text4.strip():
            all_texts.append(text4)
        
        # Configuration 5: Sparse text (for vertical columns)
        config5 = '--oem 3 --psm 11'  # Sparse text
        text5 = pytesseract.image_to_string(processed_image, lang='eng', config=config5)
        if text5.strip():
            all_texts.append(text5)
        
        # Configuration 6: Raw line (for vertical digits with special chars)
        config6 = '--oem 3 --psm 6 -c tessedit_char_whitelist=0123456789*S'  # Digits and *S
        text6 = pytesseract.image_to_string(processed_image, lang='eng', config=config6)
        if text6.strip():
            all_texts.append(text6)
        
        # Also try rotated versions for vertical text
        for angle in [90, 180, 270]:
            rotated = processed_image.rotate(angle, expand=True)
            rotated_text = pytesseract.image_to_string(rotated, lang='eng', config='--oem 3 --psm 6')
            if rotated_text.strip():
                all_texts.append(rotated_text)
        
        # Combine all extracted texts (remove duplicates)
        combined_text = '\n'.join(set(all_texts)) if all_texts else pytesseract.image_to_string(processed_image, lang='eng')
        
        # Fallback to original if preprocessing failed
        if not combined_text.strip():
            combined_text = pytesseract.image_to_string(image, lang='eng')
        
        return {
            'rawText': combined_text,
            'fullName': extract_name(combined_text),
            'idNumber': extract_id_number(combined_text),
            'dateOfBirth': extract_date_of_birth(combined_text)
        }
    except Exception as e:
        # print(f"OCR Error: {e}")
        # Fallback to basic OCR
        try:
            image_data = base64.b64decode(image_base64)
            image = Image.open(io.BytesIO(image_data))
            if image.mode != 'RGB':
                image = image.convert('RGB')
            raw_text = pytesseract.image_to_string(image, lang='eng')
            return {
                'rawText': raw_text,
                'fullName': extract_name(raw_text),
                'idNumber': extract_id_number(raw_text),
                'dateOfBirth': extract_date_of_birth(raw_text)
            }
        except:
            return None

def compare_faces_internal(id_image_base64, selfie_image_base64):
    """Internal function to compare faces using InsightFace (correct implementation)"""
    try:
        id_image_data = base64.b64decode(id_image_base64)
        selfie_image_data = base64.b64decode(selfie_image_base64)
        
        id_np = np.frombuffer(id_image_data, np.uint8)
        selfie_np = np.frombuffer(selfie_image_data, np.uint8)
        
        id_cv = cv2.imdecode(id_np, cv2.IMREAD_COLOR)
        selfie_cv = cv2.imdecode(selfie_np, cv2.IMREAD_COLOR)
        
        if id_cv is None or selfie_cv is None:
            return {'isMatch': False, 'confidence': 0.0, 'similarity': 0.0, 'message': 'Failed to decode images'}
        
        id_faces = face_model.get(id_cv)
        selfie_faces = face_model.get(selfie_cv)
        
        # Enforce exactly one face per image
        if len(id_faces) == 0:
            return {'isMatch': False, 'confidence': 0.0, 'similarity': 0.0, 'message': 'No face detected in ID image'}
        
        if len(selfie_faces) == 0:
            return {'isMatch': False, 'confidence': 0.0, 'similarity': 0.0, 'message': 'No face detected in selfie'}
        
        if len(id_faces) > 1:
            return {'isMatch': False, 'confidence': 0.0, 'similarity': 0.0, 'message': 'Multiple faces detected in ID image'}
        
        if len(selfie_faces) > 1:
            return {'isMatch': False, 'confidence': 0.0, 'similarity': 0.0, 'message': 'Multiple faces detected in selfie'}
        
        id_face = id_faces[0]
        selfie_face = selfie_faces[0]
        
        # Check face quality
        if id_face.det_score < 0.6:
            return {'isMatch': False, 'confidence': 0.0, 'similarity': 0.0, 'message': 'Low-quality face in ID image'}
        
        if selfie_face.det_score < 0.6:
            return {'isMatch': False, 'confidence': 0.0, 'similarity': 0.0, 'message': 'Low-quality face in selfie'}
        
        # Check face size
        id_bbox = id_face.bbox
        selfie_bbox = selfie_face.bbox
        id_face_width = id_bbox[2] - id_bbox[0]
        selfie_face_width = selfie_bbox[2] - selfie_bbox[0]
        
        if id_face_width < 100:
            return {'isMatch': False, 'confidence': 0.0, 'similarity': 0.0, 'message': 'ID face too small'}
        
        if selfie_face_width < 100:
            return {'isMatch': False, 'confidence': 0.0, 'similarity': 0.0, 'message': 'Selfie face too small'}
        
        # Use NORMED embeddings (CRITICAL)
        id_embedding = id_face.normed_embedding
        selfie_embedding = selfie_face.normed_embedding
        
        # Cosine similarity = dot product when embeddings are normalized
        similarity = float(np.dot(id_embedding, selfie_embedding))
        
        # Threshold: ≥ 0.12 for PASS (12% threshold)
        threshold = 0.12
        is_match = similarity >= threshold
        
        return {
            'isMatch': is_match,
            'confidence': float(similarity),
            'similarity': float(similarity),
            'message': 'Face match confirmed' if is_match else f'Face does not match (similarity: {similarity:.2f}, required: {threshold})'
        }
    except Exception as e:
        return {'isMatch': False, 'confidence': 0.0, 'similarity': 0.0, 'message': f'Error: {str(e)}'}

def extract_name(text):
    """Extract name from OCR text"""
    lines = [line.strip() for line in text.split('\n') if line.strip()]
    for line in lines[:5]:
        if len(line) >= 3 and len(line) <= 40:
            words = line.split()
            if 2 <= len(words) <= 4:
                if all(word.replace('-', '').replace("'", '').isalpha() for word in words):
                    return line
    return None

def extract_id_number(text):
    """Extract ID number from OCR text (handles vertical columns and prefixes like S)"""
    import re
    
    # Pattern 1: Standard ID numbers (6-15 digits)
    id_pattern1 = re.compile(r'\b\d{6,15}\b')
    matches1 = id_pattern1.findall(text)
    
    # Pattern 2: ID with prefix (e.g., S548025, *S548025*)
    id_pattern2 = re.compile(r'[S*]\s*\d{4,15}\s*[*]?', re.IGNORECASE)
    matches2 = id_pattern2.findall(text)
    
    # Pattern 3: Vertical column format (digits separated by spaces/newlines)
    # Extract all digits and try to find sequences
    all_digits = re.findall(r'\d', text)
    digit_sequence = ''.join(all_digits)
    
    # Try to find ID number patterns in digit sequence
    id_pattern3 = re.compile(r'\d{6,15}')
    matches3 = id_pattern3.findall(digit_sequence)
    
    # Combine all matches
    all_matches = matches1 + [re.sub(r'[^\d]', '', m) for m in matches2] + matches3
    
    if all_matches:
        # Return the longest match (most likely to be ID number)
        return max(all_matches, key=len)
    
    return None

def extract_date_of_birth(text):
    """Extract date of birth from OCR text"""
    import re
    date_patterns = [
        re.compile(r'\b\d{2}[/-]\d{2}[/-]\d{4}\b'),
        re.compile(r'\b\d{4}[/-]\d{2}[/-]\d{2}\b'),
        re.compile(r'\b\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\b'),
    ]
    for pattern in date_patterns:
        match = pattern.search(text)
        if match:
            return match.group(0)
    return None

def detect_id_type(text):
    """Detect if ID is government-issued or student ID"""
    text_lower = text.lower()
    
    government_indicators = [
        'driver', 'driving', 'license', 'dl', 'd.l.',
        'national id', 'national identification', 'nid', 'national identity',
        'passport', 'passport no', 'passport number',
        'department of motor vehicles', 'dmv', 'd.m.v.',
        'department of state', 'ministry of', 'government',
        'republic of', 'federal', 'state id', 'state identification',
        'official', 'authorized', 'issued by', 'government issued',
        'valid until', 'expires', 'expiration date',
    ]
    
    student_indicators = [
        'student', 'student id', 'student identification',
        'university', 'college', 'school', 'academic',
        'student number', 'matriculation', 'enrollment',
        'campus', 'institution', 'educational',
    ]
    
    gov_matches = sum(1 for indicator in government_indicators if indicator in text_lower)
    student_matches = sum(1 for indicator in student_indicators if indicator in text_lower)
    
    if gov_matches >= 2:
        return 'government'
    elif student_matches >= 2:
        return 'student'
    elif gov_matches > 0:
        return 'government'
    elif student_matches > 0:
        return 'student'
    else:
        return 'unknown'

def validate_text(extracted_data, user_input_id_number, user_input_first_name, 
                  user_input_last_name, user_input_birthday):
    """Validate extracted text against user input using fuzzy matching"""
    # Validate ID number (≥95% match)
    id_number_valid = False
    if extracted_data.get('idNumber') and user_input_id_number:
        extracted_id = ''.join(filter(str.isdigit, extracted_data['idNumber']))
        user_id = ''.join(filter(str.isdigit, user_input_id_number))
        similarity = fuzz.ratio(extracted_id, user_id) / 100.0
        id_number_valid = similarity >= 0.95
    
    # Validate name (≥80% match)
    name_valid = False
    if extracted_data.get('fullName'):
        extracted_name = extracted_data['fullName'].lower()
        user_full_name = f"{user_input_first_name} {user_input_last_name}".lower().strip()
        similarity = fuzz.ratio(extracted_name, user_full_name) / 100.0
        name_valid = similarity >= 0.80
        
        if not name_valid:
            first_sim = fuzz.ratio(extracted_name, user_input_first_name.lower()) / 100.0
            last_sim = fuzz.ratio(extracted_name, user_input_last_name.lower()) / 100.0
            name_valid = (first_sim >= 0.80 or last_sim >= 0.80 or
                         user_input_first_name.lower() in extracted_name or
                         user_input_last_name.lower() in extracted_name)
    
    # Validate birthday (exact or ≥95% match)
    birthday_valid = True
    if user_input_birthday and extracted_data.get('dateOfBirth'):
        extracted_date = ''.join(filter(str.isdigit, extracted_data['dateOfBirth']))
        user_date = ''.join(filter(str.isdigit, user_input_birthday))
        birthday_valid = extracted_date == user_date or fuzz.ratio(extracted_date, user_date) / 100.0 >= 0.95
    
    return {
        'isValid': id_number_valid and name_valid and birthday_valid,
        'idNumberMatch': id_number_valid,
        'nameMatch': name_valid,
        'birthdayMatch': birthday_valid
    }

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False)

