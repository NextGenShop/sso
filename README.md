proxy_set_header Forwarded $proxy_add_forwarded;
proxy_set_header Forwarded "$proxy_add_forwarded;proto=$scheme";

X-Forwarded-For: 12.34.56.78, 23.45.67.89
X-Real-IP: 12.34.56.78
X-Forwarded-Host: example.com
X-Forwarded-Proto: https
