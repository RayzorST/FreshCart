FROM nginx:alpine

# Копирование предварительно собранного приложения
COPY build/web /usr/share/nginx/html

# Базовая конфигурация nginx для SPA
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]