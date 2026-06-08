from pydantic import BaseModel, Field


class ChatRequest(BaseModel):
    userId: str = Field(default='')
    message: str = Field(min_length=1)


class ChatResponse(BaseModel):
    reply: str
    intent: str
    confidence: float
