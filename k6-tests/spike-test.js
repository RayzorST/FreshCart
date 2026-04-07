import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';
import { login, analyzeImage, getTestImage } from './utils.js';

const imageBase64 = getTestImage();

const errorRate = new Rate('errors');
const aiProcessingTime = new Trend('ai_processing_time', true);

export const options = {
  stages: [
    { duration: '1m', target: 5 },      // спокойный режим
    { duration: '10s', target: 80 },    // РЕЗКИЙ СКАЧОК до 80 пользователей
    { duration: '1m', target: 80 },     // держим нагрузку
    { duration: '30s', target: 0 },     // спад
  ],
  thresholds: {
    'http_req_duration': ['p(95)<15000'],
    'errors': ['rate<0.15'],
  },
};

export default function () {
  const baseUrl = 'http://localhost:8000';
  
  if (!imageBase64) {
    errorRate.add(true);
    sleep(1);
    return;
  }
  
  const token = login(baseUrl, 'admin@freshcart.com', 'admin');
  
  if (!token) {
    errorRate.add(true);
    sleep(2);
    return;
  }
  
  const aiStart = Date.now();
  const res = analyzeImage(baseUrl, imageBase64, token);
  aiProcessingTime.add(Date.now() - aiStart);
  
  const success = check(res, {
    'status is 200 or 429': (r) => r.status === 200 || r.status === 429,
  });
  
  errorRate.add(!success);
  
  if (res.status === 200) {
    const body = JSON.parse(res.body);
    console.log(`✅ ${body.detected_dish}`);
  }
  
  sleep(Math.random() * 3 + 1);
}