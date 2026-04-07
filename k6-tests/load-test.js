import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';
import { login, analyzeImage, getTestImage } from './utils.js';

// Загружаем изображение в init-контексте
const imageBase64 = getTestImage();

// Метрики
const errorRate = new Rate('errors');
const aiProcessingTime = new Trend('ai_processing_time', true);
const loginTime = new Trend('login_time', true);

export const options = {
  stages: [
    { duration: '30s', target: 5 },    // разогрев до 5 VU
    { duration: '1m', target: 20 },    // до 20 VU
    { duration: '1m', target: 30 },    // до 30 VU
    { duration: '30s', target: 0 },    // спад
  ],
  thresholds: {
    'http_req_duration': ['p(95)<10000'],
    'ai_processing_time': ['p(95)<7000'],
    'errors': ['rate<0.1'],
  },
};

export default function () {
  const baseUrl = 'http://localhost:8000';
  
  if (!imageBase64) {
    errorRate.add(true);
    console.error('❌ Image not loaded');
    sleep(1);
    return;
  }
  
  // Измеряем время авторизации
  const loginStart = Date.now();
  const token = login(baseUrl, 'admin@freshcart.com', 'admin');
  loginTime.add(Date.now() - loginStart);
  
  if (!token) {
    errorRate.add(true);
    console.error(`[VU ${__VU}] ❌ Login failed`);
    sleep(2);
    return;
  }
  
  // Измеряем время обработки ИИ
  const aiStart = Date.now();
  const res = analyzeImage(baseUrl, imageBase64, token);
  aiProcessingTime.add(Date.now() - aiStart);
  
  const success = check(res, {
    'status is 200': (r) => r.status === 200,
    'has detected dish': (r) => JSON.parse(r.body).detected_dish !== undefined,
  });
  
  errorRate.add(!success);
  
  if (res.status === 200) {
    const body = JSON.parse(res.body);
    console.log(`[VU ${__VU}] ✅ ${body.detected_dish} (${body.confidence})`);
  } else if (res.status === 401) {
    console.error(`[VU ${__VU}] ❌ Unauthorized`);
  } else if (res.status === 500) {
    console.error(`[VU ${__VU}] ❌ Server error: ${res.body}`);
  }
  
  sleep(3);
}