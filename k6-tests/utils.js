// utils.js (упрощённая версия с предварительно закодированным изображением)
import http from 'k6/http';

// Читаем предварительно закодированный base64 из файла
const base64Data = open('./test-image-base64.txt', 'r').trim();
const cachedImageBase64 = `data:image/jpeg;base64,${base64Data}`;

export function getTestImage() {
  return cachedImageBase64;
}

export function login(baseUrl, email, password) {
  const payload = JSON.stringify({ email, password });
  const res = http.post(`${baseUrl}/auth/login`, payload, {
    headers: { 'Content-Type': 'application/json' },
  });
  if (res.status === 200) {
    return JSON.parse(res.body).access_token;
  }
  return null;
}

export function analyzeImage(baseUrl, imageBase64, token) {
  const payload = JSON.stringify({ image_data: imageBase64 });
  return http.post(`${baseUrl}/ai/base64`, payload, {
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`,
    },
  });
}