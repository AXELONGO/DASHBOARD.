# Manual Técnico Detallado: DASHBOARD CON IA

Este documento proporciona una explicación profunda de la arquitectura, estructura de archivos y funcionamiento del código del proyecto "DASHBOARD CON IA". Está diseñado para permitir que cualquier desarrollador entienda, mantenga y expanda el sistema.

---

## 1. Arquitectura del Sistema

El proyecto utiliza una arquitectura de **Microservicios Contenerizados** orquestados con Docker Compose. Se divide en dos servicios principales:

1.  **Frontend (Cliente)**: Aplicación React servida por Nginx.
2.  **Backend (Servidor)**: API REST en Node.js/Express.

### Diagrama de Flujo de Datos

```mermaid
graph TD
    User[Usuario Final] -->|HTTP Puerto 8081| Nginx[Nginx (Frontend Container)]
    
    subgraph "Contenedor Frontend"
        Nginx -->|Ruta /| ReactApp[React App (Archivos Estáticos)]
        Nginx -->|Ruta /api/*| Proxy[Reverse Proxy]
    end
    
    subgraph "Contenedor Backend"
        Proxy -->|HTTP Puerto 3001| Express[Node.js Express Server]
    end
    
    Express -->|HTTPS| NotionAPI[Notion API (Base de Datos)]
    Express -->|HTTPS POST| N8N[N8N Webhook (Automatización)]
```

---

## 2. Tecnologías y Librerías Clave

### Frontend
*   **React 18**: Librería de UI basada en componentes.
*   **Vite**: Build tool de última generación, mucho más rápido que Webpack.
*   **Tailwind CSS**: Framework de estilos. Permite diseñar directamente en el HTML (JSX).
*   **jsPDF & jspdf-autotable**: Generación de PDFs en el lado del cliente (navegador).
*   **Lucide React / Material Symbols**: Iconografía.

### Backend
*   **Node.js & Express**: Servidor ligero y flexible.
*   **@notionhq/client**: Cliente oficial para interactuar con Notion.
*   **cors**: Middleware para permitir peticiones entre dominios (aunque Nginx maneja esto en producción).
*   **dotenv**: Carga de variables de entorno seguras.

---

## 3. Explicación Detallada de Archivos

A continuación se describe cada archivo crítico y su función.

### A. Infraestructura (`docker-compose.yml`)
Este archivo define cómo se levantan los servicios.

```yaml
version: '3.8'
services:
  erp-dashboard: # Servicio Frontend
    build: .
    ports:
      - "8081:80" # Mapea puerto 8081 de tu PC al 80 del contenedor
    depends_on:
      - backend # Espera a que el backend inicie

  backend: # Servicio Backend
    build: ./backend
    ports:
      - "3001:3001"
    environment: # Pasa las claves secretas al contenedor
      - NOTION_API_KEY=${VITE_NOTION_API_KEY}
      ...
```

### B. Configuración del Servidor Web (`nginx.conf`)
Nginx es crucial porque une el Frontend y el Backend en un solo dominio aparente, evitando problemas de CORS.

```nginx
server {
    listen 80;
    
    # Sirve la aplicación React
    location / {
        root /usr/share/nginx/html;
        try_files $uri $uri/ /index.html;
    }

    # Redirige las llamadas /api al contenedor del backend
    location /api/ {
        proxy_pass http://backend:3001/api/;
    }
}
```

### C. Backend (`backend/server.js`)
Es el cerebro que protege tus claves de API. El Frontend nunca habla directo con Notion, habla con este archivo.

**Ejemplo: Endpoint para obtener Leads**
```javascript
app.get('/api/leads', async (req, res) => {
    // 1. Obtiene el ID de la base de datos de las variables de entorno
    const databaseId = process.env.NOTION_DATABASE_ID;

    try {
        // 2. Consulta a Notion
        const response = await notion.databases.query({
            database_id: databaseId,
            page_size: 100,
        });

        // 3. Limpia y formatea los datos para el Frontend
        const cleanLeads = response.results.map(page => ({
            id: page.id,
            name: page.properties['Name']?.title[0]?.plain_text || 'Sin Nombre',
            // ... más mapeo de datos
        }));

        res.json(cleanLeads); // 4. Responde al Frontend
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});
```

**Ejemplo: Proxy para Webhook (N8N)**
Este endpoint recibe los datos del formulario y los reenvía a N8N.
```javascript
app.post('/api/webhook', async (req, res) => {
    const webhookUrl = 'https://tu-n8n.com/webhook/...';
    
    // Reenvía la petición POST tal cual llega
    const response = await fetch(webhookUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(req.body)
    });
    // ...
});
```

### D. Frontend - Servicio de API (`services/notionService.ts`)
Encapsula las llamadas al Backend. Si cambia la URL del backend, solo cambias este archivo.

```typescript
const API_BASE_URL = "/api"; // Nginx redirigirá esto

export const getLeadsFromNotion = async (): Promise<Lead[]> => {
    const response = await fetch(`${API_BASE_URL}/leads`);
    if (!response.ok) throw new Error("Error fetching leads");
    return await response.json();
};
```

### E. Frontend - Vista de Cotizaciones (`components/QuotesView.tsx`)
Maneja la lógica del formulario y el envío.

**Lógica del Botón de Envío:**
```typescript
const handleSendWhatsApp = async () => {
    setIsWhatsappLoading(true); // Muestra spinner
    
    // 1. Construye el objeto de datos (Payload)
    const payload = {
        cliente: selectedLead?.name,
        telefono: selectedLead?.phone,
        items: items, // Array de productos
        total: calculateTotal(),
        // ...
    };

    // 2. Envía al Backend (que enviará a N8N)
    await fetch('/api/webhook', {
        method: 'POST',
        body: JSON.stringify(payload)
    });
    
    setIsWhatsappLoading(false);
};
```

### F. Frontend - Generación de PDF (`services/pdfService.ts`)
Utiliza `jsPDF` para dibujar el reporte pixel por pixel.

**Validación de Fechas (Corrección "Invalid Date"):**
```typescript
// Intenta parsear la fecha ISO
if (item.isoDate) {
    try {
        timeStr = new Date(item.isoDate).toLocaleTimeString('es-MX', ...);
    } catch (e) { ... }
}

// Regla de seguridad final
if (timeStr.includes("Invalid")) {
    timeStr = "--:--"; // Fallback seguro
}
```

---

## 4. Flujo de Trabajo (Workflow)

### Paso 1: Inicio de la Aplicación
Al ejecutar `docker compose up`, Docker construye las imágenes. El Backend se conecta a Notion y espera peticiones. El Frontend se compila y Nginx empieza a servirlo en el puerto 8081.

### Paso 2: Interacción del Usuario
El usuario entra a `localhost:8081`. React monta `App.tsx`.
`App.tsx` llama a `getLeadsFromNotion()`.
La petición viaja: `Navegador -> Nginx -> Backend -> Notion`.
Los datos regresan y React renderiza la lista de clientes.

### Paso 3: Envío de Cotización
El usuario selecciona productos y da clic en "Envio de Cotizacion".
React captura los datos y los envía a `/api/webhook`.
El Backend recibe el JSON y lo envía a N8N.
N8N recibe el JSON y dispara su flujo (ej. mandar mensaje de WhatsApp).

---

## 5. Guía de Solución de Problemas (Troubleshooting)

### El botón de envío no hace nada
*   **Causa probable**: Un elemento invisible está tapando el botón o hay un error de JavaScript silencioso.
*   **Solución**: Se añadió un **Botón Flotante** de respaldo y alertas de depuración (`alert("DEBUG...")`). Si ves la alerta, el botón funciona y el error es del servidor.

### Error "Invalid Date" en PDF
*   **Causa**: Notion a veces devuelve fechas en formatos inconsistentes o nulos.
*   **Solución**: El código ahora verifica explícitamente si la fecha es válida antes de escribirla en el PDF. Si falla, pone la hora actual o "--:--".

### No se ven los cambios en GitHub
*   **Causa**: Estás trabajando en local. Git necesita que hagas `push` al servidor remoto.
*   **Solución**: Ejecutar `git push origin main`. (Nota: El archivo `.env` está ignorado por seguridad, así que tus claves nunca se subirán).
