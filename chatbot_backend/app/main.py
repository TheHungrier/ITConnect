from fastapi import FastAPI, Header, HTTPException
from fastapi.middleware.cors import CORSMiddleware

from .chat_service import ChatService
from .schemas import ChatRequest, ChatResponse

app = FastAPI(title='ITConnect Chatbot API', version='1.0.0')

app.add_middleware(
    CORSMiddleware,
    allow_origins=['*'],
    allow_credentials=True,
    allow_methods=['*'],
    allow_headers=['*'],
)

chat_service = ChatService()


@app.get('/health')
def health():
    return {
        'status': 'ok',
        'firebase_enabled': chat_service.firebase.enabled,
    }


@app.post('/chat', response_model=ChatResponse)
def chat(request: ChatRequest, authorization: str = Header(default='')):
    user_id = request.userId.strip()

    # Nếu backend có Firebase Admin SDK thì ưu tiên xác minh token.
    if authorization.startswith('Bearer '):
        token = authorization.replace('Bearer ', '').strip()
        verified_uid = chat_service.firebase.verify_id_token(token)
        if verified_uid:
            user_id = verified_uid

    if not user_id:
        raise HTTPException(status_code=401, detail='Thiếu thông tin người dùng')

    result = chat_service.reply(user_id=user_id, message=request.message)
    return ChatResponse(**result)
