# 🚀 Guía Rápida de Despliegue en VPS

## 📦 Archivos Creados

He creado estos archivos para facilitar tu despliegue:

1. **`.env.example`** - Plantilla de configuración
2. **`deploy.sh`** - Script automatizado de despliegue

---

## ⚡ Pasos Rápidos

### 1️⃣ Preparar Credenciales (EN TU PC)

```powershell
# Ir a la carpeta del proyecto
cd "c:\Users\DELL\Downloads\dashboard new"

# Copiar la plantilla
Copy-Item .env.example .env

# Editar con tus credenciales reales
notepad .env
```

**Necesitas conseguir:**
- 🔑 **Notion API Key**: https://www.notion.so/my-integrations
- 📊 **Database IDs**: Copia desde la URL de tus bases de datos en Notion
- 🤖 **Gemini API Key**: https://aistudio.google.com/app/apikey

---

### 2️⃣ Conectar a tu VPS

```bash
ssh usuario@tu-servidor.com
```

---

### 3️⃣ Instalar Docker (si no lo tienes)

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y docker.io docker-compose
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
```

> ⚠️ **Importante**: Cierra y vuelve a abrir la terminal después de este paso

---

### 4️⃣ Subir tu Código al VPS

**Opción A: Con Git** (Recomendado)
```bash
git clone https://github.com/AXELONGO/DASHBOARD..git dashboard
cd dashboard
```

**Opción B: Con SCP** (Desde tu PC Windows)
```powershell
# Desde PowerShell en tu PC
scp -r "c:\Users\DELL\Downloads\dashboard new" usuario@tu-servidor:~/dashboard
```

---

### 5️⃣ Configurar Variables de Entorno en el VPS

```bash
cd dashboard

# Copiar plantilla
cp .env.example .env

# Editar con tus credenciales
nano .env
```

Pega tus credenciales y guarda con: **Ctrl + O** → **Enter** → **Ctrl + X**

---

### 6️⃣ Desplegar Automáticamente

```bash
# Dar permisos al script
chmod +x deploy.sh

# Ejecutar despliegue
./deploy.sh
```

El script automáticamente:
- ✅ Verifica que tengas `.env` configurado
- ✅ Detiene contenedores anteriores
- ✅ Construye las imágenes Docker
- ✅ Levanta los servicios
- ✅ Te muestra la URL para acceder

---

### 7️⃣ Abrir el Puerto (Si usas Firewall)

**Con UFW (Ubuntu):**
```bash
sudo ufw allow 8081/tcp
sudo ufw reload
```

**Con Google Cloud:**
- Ve a **Red de VPC** → **Firewall**
- Crea regla: `allow-erp-8081`, TCP puerto `8081`, origen `0.0.0.0/0`

---

## 🌐 Acceder a tu Aplicación

Tu dashboard estará disponible en:
```
http://TU_IP_DEL_VPS:8081
```

Para ver tu IP:
```bash
curl ifconfig.me
```

---

## 🛠️ Comandos Útiles

```bash
# Ver logs en tiempo real
docker-compose logs -f

# Ver estado de containers
docker-compose ps

# Reiniciar servicios
docker-compose restart

# Detener todo
docker-compose down

# Reconstruir después de cambios en el código
./deploy.sh
```

---

## 🔍 Solución de Problemas

### El puerto 8081 no funciona
```bash
# Verificar que los contenedores estén corriendo
docker-compose ps

# Ver logs de errores
docker-compose logs backend
docker-compose logs erp-dashboard
```

### Error con credenciales
```bash
# Verificar que .env existe y tiene valores
cat .env

# Reiniciar servicios después de editar .env
docker-compose down
docker-compose up -d
```

### El contenedor no inicia
```bash
# Ver logs detallados
docker-compose logs --tail=100

# Reconstruir desde cero
docker-compose down
docker system prune -af
./deploy.sh
```

---

## 📞 Checklist Final

Antes de desplegar, asegúrate de tener:

- [ ] Archivo `.env` con credenciales reales
- [ ] Docker instalado en el VPS
- [ ] Puerto 8081 abierto en el firewall
- [ ] Código subido al VPS
- [ ] Permisos de ejecución en `deploy.sh` (`chmod +x`)

---

## 🎉 ¡Listo!

Una vez completados estos pasos, tu Dashboard ERP estará funcionando en tu VPS sin necesidad de autenticación de Google.
