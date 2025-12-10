# ✅ Configuración Simplificada - Backend Integrado

## 🎯 Cambios Realizados

He simplificado la configuración de Docker para evitar problemas con carpetas separadas:

### Antes
- ❌ `docker-compose.yml` buscaba `./backend/Dockerfile`
- ❌ Requería que la carpeta `backend/` existiera en el VPS

### Ahora
- ✅ `Dockerfile.backend` está en la raíz del proyecto
- ✅ Construye desde la raíz copiando solo los archivos de backend necesarios
- ✅ No depende de la estructura de carpetas

---

## 🚀 Instrucciones para el VPS

### 1. Actualizar el código

```bash
cd ~/dashboard-sin-loggin
git pull
```

### 2. Verificar archivos nuevos

```bash
ls -la | grep Dockerfile
```

Deberías ver:
- `Dockerfile` (frontend)
- `Dockerfile.backend` (backend) ← **NUEVO**

### 3. Crear/Verificar archivo .envierno

```bash
nano .env
```

Contenido mínimo requerido:
```env
NOTION_API_KEY=secret_TU_CLAVE_AQUI
NOTION_DATABASE_ID=TU_ID_DB_LEADS
NOTION_HISTORY_DB_ID=TU_ID_HISTORIAL
VITE_NOTION_API_KEY=secret_TU_CLAVE_AQUI
VITE_NOTION_DATABASE_ID=TU_ID_DB_LEADS
VITE_NOTION_HISTORY_DB_ID=TU_ID_HISTORIAL
VITE_GEMINI_API_KEY=TU_GEMINI_KEY
GOOGLE_CLIENT_ID=dummy
VITE_GOOGLE_CLIENT_ID=dummy
```

### 4. Desplegar

```bash
docker-compose down
docker-compose up -d --build
```

### 5. Verificar que funciona

```bash
# Ver logs
docker-compose logs -f

# Ver estado
docker-compose ps
```

---

## 🔍 Solución de Problemas

### Si sigue sin funcionar después de `git pull`

```bash
# Listar TODO lo que hay en la carpeta
ls -la

# Verificar específicamente la carpeta backend
ls -la backend/

# Si la carpeta backend NO existe, entonces:
git status
git log --oneline -5
```

### Verificar que los Dockerfiles existan

```bash
cat Dockerfile.backend
```

Debería mostrar el contenido del Dockerfile del backend.

---

## 📊 Arquitectura Nueva

```
proyecto/
├── Dockerfile           # Frontend (React + Nginx)
├── Dockerfile.backend   # Backend (Node.js + Express) ← NUEVO
├── docker-compose.yml   # Orquestación (apunta a ambos)
├── backend/             # Código fuente del backend
│   ├── server.js
│   ├── package.json
│   └── ...
├── components/          # Componentes React
├── services/            # Servicios de Notion/Gemini
└── .env                 # Variables de entorno
```

**Ventaja**: Docker construye desde la raíz, copiando solo lo necesario de `backend/`, sin requerir que Docker entre a subcarpetas.

---

## ✅ Checklist de Verificación

Antes de ejecutar `docker-compose up`:

- [ ] Hiciste `git pull`
- [ ] Existe el archivo `Dockerfile.backend` en la raíz
- [ ] Existe el archivo `.env` con tus credenciales
- [ ] La carpeta `backend/` contiene `server.js` y `package.json`
