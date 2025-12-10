#!/bin/bash
# =====================================================
# Script de Despliegue Automático para VPS
# =====================================================

echo "🚀 Iniciando despliegue del Dashboard ERP..."

# Colores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Función para errores
error_exit() {
    echo -e "${RED}❌ Error: $1${NC}" 1>&2
    exit 1
}

# Verificar que estamos en la carpeta correcta
if [ ! -f "package.json" ]; then
    error_exit "No se encuentra package.json. Asegúrate de estar en la carpeta del proyecto."
fi

# Verificar que existe .env
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}⚠️  No se encontró archivo .env${NC}"
    echo "Creando .env desde .env.example..."
    
    if [ -f ".env.example" ]; then
        cp .env.example .env
        echo -e "${YELLOW}📝 Por favor edita .env con tus credenciales reales antes de continuar${NC}"
        echo "Presiona ENTER cuando hayas terminado..."
        read
    else
        error_exit "No se encuentra .env ni .env.example"
    fi
fi

# Validar que .env tiene valores reales
if grep -q "TU_.*_AQUI" .env; then
    echo -e "${RED}⚠️  ADVERTENCIA: .env contiene valores placeholder${NC}"
    echo "Por favor completa tus credenciales reales en .env"
    echo "¿Deseas continuar de todas formas? (s/N)"
    read -r response
    if [[ ! "$response" =~ ^[Ss]$ ]]; then
        exit 1
    fi
fi

echo -e "${GREEN}✓ Archivo .env encontrado${NC}"

# Detener contenedores anteriores
echo "🛑 Deteniendo contenedores anteriores..."
docker-compose down 2>/dev/null || true

# Limpiar imágenes antiguas (opcional)
echo "🧹 Limpiando imágenes antiguas..."
docker system prune -f

# Construir y levantar
echo -e "${GREEN}🔨 Construyendo contenedores...${NC}"
docker-compose build --no-cache || error_exit "Fallo al construir contenedores"

echo -e "${GREEN}🚀 Levantando servicios...${NC}"
docker-compose up -d || error_exit "Fallo al levantar servicios"

# Esperar a que los servicios estén listos
echo "⏳ Esperando a que los servicios inicien..."
sleep 5

# Verificar estado
echo -e "\n${GREEN}📊 Estado de los contenedores:${NC}"
docker-compose ps

# Mostrar logs recientes
echo -e "\n${GREEN}📋 Últimos logs:${NC}"
docker-compose logs --tail=20

# Obtener IP del servidor
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')

echo -e "\n${GREEN}✅ ¡Despliegue completado!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "🌐 Tu aplicación está disponible en:"
echo -e "   ${YELLOW}http://${SERVER_IP}:8081${NC}"
echo -e "\n📝 Comandos útiles:"
echo -e "   ${YELLOW}docker-compose logs -f${NC}          # Ver logs en tiempo real"
echo -e "   ${YELLOW}docker-compose restart${NC}          # Reiniciar servicios"
echo -e "   ${YELLOW}docker-compose down${NC}             # Detener todo"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
