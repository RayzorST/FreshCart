import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';
import { login, analyzeImage, getTestImage } from './utils.js';

const imageBase64 = getTestImage();

const errorRate = new Rate('errors');
const aiProcessingTime = new Trend('ai_processing_time', true);

export const options = {
  stages: [
    { duration: '30s', target: 10 },    // разогрев
    { duration: '30s', target: 30 },    // 30 VU
    { duration: '30s', target: 60 },    // 60 VU
    { duration: '30s', target: 100 },   // 100 VU
    { duration: '30s', target: 150 },   // 150 VU
    { duration: '1m', target: 150 },    // держим нагрузку
    { duration: '30s', target: 0 },     // спад
  ],
  thresholds: {
    'errors': ['rate<0.2'],
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
    sleep(1);
    return;
  }
  
  const aiStart = Date.now();
  const res = analyzeImage(baseUrl, imageBase64, token);
  aiProcessingTime.add(Date.now() - aiStart);
  
  const success = check(res, {
    'status is 200': (r) => r.status === 200,
  });
  
  errorRate.add(!success);
  
  sleep(0.5);
}

import { htmlReport } from 'https://raw.githubusercontent.com/benc-uk/k6-reporter/main/dist/bundle.js';

export function handleSummary(data) {
  return {
    'report.html': htmlReport(data),
  };
}