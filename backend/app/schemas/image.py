from pydantic import BaseModel

class ImageBase64(BaseModel):
    image_data: str  # base64 строка