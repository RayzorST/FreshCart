import { check, sleep } from 'k6';
import { login, analyzeImage, getTestImage } from './utils.js';

// Загружаем изображение в init-контексте
const imageBase64 = getTestImage();

export const options = {
  vus: 1,
  duration: '30s',
};

export default function () {
  const baseUrl = 'http://localhost:8000';
  
  // Проверяем, что изображение загружено
  if (!imageBase64) {
    console.error('❌ Image not loaded, skipping test');
    return;
  }
  
  // 2. Авторизация
  const token = login(baseUrl, 'admin@freshcart.com', 'admin');
  if (!token) {
    console.error('❌ Login failed');
    return;
  }
  console.log('✅ Login successful');
  
  // 3. Отправляем на анализ
  const res = analyzeImage(baseUrl, imageBase64, token);
  
  check(res, {
    'status is 200': (r) => r.status === 200,
    'response time < 10s': (r) => r.timings.duration < 10000,
    'has detected_dish': (r) => JSON.parse(r.body).detected_dish !== undefined,
    'has basic_ingredients': (r) => JSON.parse(r.body).basic_ingredients !== undefined,
    'has alternatives': (r) => JSON.parse(r.body).basic_alternatives !== undefined,
    'success is true': (r) => JSON.parse(r.body).success === true,
  });
  
  if (res.status === 200) {
    const body = JSON.parse(res.body);
    console.log(`🍽️ Распознано блюдо: ${body.detected_dish}`);
    console.log(`📊 Уверенность: ${body.confidence}`);
    console.log(`🥕 Основные ингредиенты: ${body.basic_ingredients.join(', ')}`);
  } else {
    console.error(`❌ Error: ${res.status} - ${res.body}`);
  }
  
  sleep(2);
}