# Guía de Despliegue en Google Cloud Platform (VPS)

Esta guía te llevará paso a paso para subir tu aplicación a una instancia VPS en Google Cloud.

## Requisitos Previos
1.  Una cuenta activa en Google Cloud Platform.
2.  Tu código subido a GitHub (ya lo hemos hecho).
3.  Tus claves de API (Notion, Google, Gemini) a mano.

---

## Paso 1: Crear la Instancia (VPS)

1.  Ve a **Google Cloud Console** > **Compute Engine** > **Instancias de VM**.
2.  Haz clic en **Crear Instancia**.
3.  **Configuración recomendada**:
    *   **Nombre**: `erp-dashboard`
    *   **Región**: `us-central1` (o la más cercana a ti).
    *   **Tipo de máquina**: `e2-medium` (2 vCPU, 4GB RAM) es ideal para empezar. `e2-small` podría quedarse corta al construir Docker.
    *   **Disco de arranque**: Cambiar a **Ubuntu 22.04 LTS** (x86/64), 20 GB de disco estándar.
    *   **Firewall**: Marca las casillas "Permitir tráfico HTTP" y "Permitir tráfico HTTPS".
4.  Haz clic en **Crear**.

---

## Paso 2: Configurar el Firewall (Abrir Puerto 8081)

Por defecto, Google bloquea casi todos los puertos. Necesitamos abrir el puerto `8081` donde corre tu app.

1.  En el menú de Google Cloud, busca **Red de VPC** > **Firewall**.
2.  Haz clic en **Crear regla de firewall**.
3.  **Nombre**: `allow-erp-8081`
4.  **Destinos**: `Todas las instancias de la red`.
5.  **Intervalos de IP de origen**: `0.0.0.0/0` (Permite acceso desde cualquier lugar).
6.  **Protocolos y puertos**: Marca **TCP** y escribe `8081`.
7.  Haz clic en **Crear**.

---

## Paso 3: Conectarse e Instalar Docker

1.  En la lista de instancias, haz clic en el botón **SSH** al lado de tu nueva instancia. Se abrirá una terminal en tu navegador.
2.  Ejecuta los siguientes comandos uno por uno para instalar Docker:

```bash
# Actualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar Docker
sudo apt install -y docker.io docker-compose

# Iniciar y habilitar Docker
sudo systemctl start docker
sudo systemctl enable docker

# Dar permisos a tu usuario (para no usar sudo siempre)
sudo usermod -aG docker $USER
```

3.  **IMPORTANTE**: Cierra la ventana SSH y vuelve a abrirla para que los permisos surtan efecto.

---

## Paso 4: Clonar y Configurar la App

1.  Clona tu repositorio:
    ```bash
    git clone https://github.com/AXELONGO/DASHBOARD..git app
    cd app
    ```

2.  Crea el archivo de entorno `.env`:
    ```bash
    nano .env
    ```

3.  Pega el siguiente contenido (rellena con TUS claves reales).
    *   **IMPORTANTE**: En `VITE_GOOGLE_CLIENT_ID`, asegúrate de usar el Client ID de Google.

    ```env
    VITE_NOTION_API_KEY=tu_clave_notion_aqui
    VITE_NOTION_DATABASE_ID=tu_id_db_leads
    VITE_NOTION_HISTORY_DB_ID=tu_id_db_historial
    VITE_GEMINI_API_KEY=tu_clave_gemini
    
    # Backend necesita estas también (sin prefijo VITE_)
    NOTION_API_KEY=tu_clave_notion_aqui
    NOTION_DATABASE_ID=tu_id_db_leads
    NOTION_HISTORY_DB_ID=tu_id_db_historial
    
    # Google Auth
    VITE_GOOGLE_CLIENT_ID=tu_google_client_id
    GOOGLE_CLIENT_ID=tu_google_client_id
    ```

4.  Guarda el archivo: Presiona `Ctrl + O`, `Enter`, y luego `Ctrl + X`.

---

## Paso 5: Desplegar

Ejecuta el script de construcción (o docker-compose directamente):

```bash
chmod +x rebuild.sh
./rebuild.sh
```

El proceso tardará unos minutos la primera vez.

---

## Paso 6: Configurar HTTPS y Google Auth con Ngrok (Recomendado)

Google exige HTTPS para el inicio de sesión. La forma más rápida y gratuita de conseguirlo es usando **Ngrok**.

1.  **Instalar Ngrok en el VPS**:
    Ejecuta este comando en tu terminal SSH:
    ```bash
    curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null && echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list && sudo apt update && sudo apt install ngrok
    ```

2.  **Conectar tu cuenta de Ngrok**:
    *   Regístrate gratis en [dashboard.ngrok.com](https://dashboard.ngrok.com/signup).
    *   Copia tu **Authtoken** del dashboard.
    *   Ejecuta en el VPS:
        ```bash
        ngrok config add-authtoken TU_TOKEN_AQUI
        ```

3.  **Iniciar el Túnel Seguro**:
    ```bash
    ngrok http 8081
    ```
    *   Verás una pantalla negra con una URL segura que empieza por `https://...ngrok-free.app`. **Copia esa URL**.

4.  **Actualizar Google Cloud Console**:
    *   Ve a [Google Cloud Console](https://console.cloud.google.com/apis/credentials).
    *   Edita tu Cliente OAuth.
    *   En **Orígenes de JavaScript** y **URIs de redireccionamiento**, pon tu nueva URL de Ngrok (ej. `https://tu-app.ngrok-free.app`).
    *   Guarda los cambios.

## ¡Listo!

Accede a tu aplicación usando la URL segura de Ngrok:
`https://tu-app.ngrok-free.app`
