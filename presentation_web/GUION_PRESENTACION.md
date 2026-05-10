# Guion de la Presentación: Museo Padre Suárez Digital Experience
**Duración Estimada:** 10 Minutos

## Bloque 1: Introducción y Contexto (2:30 min)

### 01. Portada (30s)
- **Mensaje:** "Buenos días, mi nombre es Alberto Ortiz y hoy voy a presentar mi Proyecto Final de Grado: La Digital Experience del Museo Padre Suárez."
- **Clave:** Enfatizar que es una transformación digital de una institución histórica.

### 02. Índice Interactivo (20s)
- **Mensaje:** "La presentación se estructura en tres bloques: El desafío estratégico, la arquitectura técnica y el despliegue de calidad profesional."

### 03. El Desafío del Museo Histórico (40s)
- **Mensaje:** "Los museos tradicionales sufren de 'estatismo'. El público digital demanda interactividad. El reto era convertir vitrinas pasivas en experiencias activas."

### 04. Identidad Visual Premium (40s)
- **Mensaje:** "Nuestra respuesta es una App multiplataforma (iOS, Android, Web) con una estética **Premium Dark Card**. No es solo una web informativa, es una interfaz minimalista diseñada para resaltar la elegancia de las piezas históricas."

### 05. Onboarding y Acceso Sin Fricción (20s)
- **Mensaje:** "La retención empieza en el primer clic. Implementamos un tutorial interactivo y un sistema de **Google Auth** de alto nivel, permitiendo al usuario sumergirse en la historia del museo en segundos."

---

## Bloque 2: Arquitectura y Desarrollo Técnico (3:30 min)

### 06. Arquitectura del Sistema (40s)
- **Mensaje:** "Usamos una arquitectura híbrida robusta. **Firebase** gestiona la identidad del usuario y las notificaciones, mientras que **Cloudinary** se encarga del almacenamiento y entrega optimizada de assets 3D mediante su sistema DAM."

### 07. Gestión de Estado - Riverpod (30s)
- **Mensaje:** "Para la lógica de negocio hemos elegido **Riverpod**. Nos permite una gestión de estado reactiva, segura y desacoplada de la interfaz, facilitando el mantenimiento a largo plazo."

### 08. Reservas y Ticketing (40s)
- **Mensaje:** "Hemos automatizado el ticketing mediante **EmailJS**. El usuario reserva desde la app y recibe instantáneamente su entrada con un código QR único en su correo electrónico."

### 09. Validación de Acceso (30s)
- **Mensaje:** "El flujo se completa en el museo físico, donde el personal valida el QR mediante el escáner integrado en la propia aplicación."

### 10. Realidad Aumentada Inmersiva (50s)
- **Punto Estrella:** "La característica diferencial es la **Realidad Aumentada (AR)**. Usando **SceneView**, proyectamos modelos 3D con iluminación realista y escala 1:1, permitiendo al usuario 'llevarse' el museo a casa."

### 11. Mapa 3D y Navegación Inteligente (30s)
- **Mensaje:** "Para completar la inmersión, hemos diseñado un **Mapa 3D interactivo** que actúa como cerebro de navegación. Es sensible al tema del sistema, transicionando entre un modo nocturno elegante y un plano técnico claro, permitiendo filtrar la colección por salas con un solo toque."

---

## Bloque 3: Blindaje, Calidad y Futuro (3:00 min)

### 11. Panel de Administración Dinámico (40s)
- **Mensaje:** "No es solo una app para visitantes; es una herramienta de gestión profesional. Hemos desarrollado un Panel Administrativo oculto que permite controlar en tiempo real el aforo, el estado de apertura y las excepciones del calendario mediante Firestore Sync."
- **Clave:** Destacar que los cambios se reflejan instantáneamente en todos los móviles de los usuarios.

### 12. Seguridad y Blindaje (40s)
- **Mensaje:** "La seguridad es prioridad. Implementamos reglas granulares en Firestore. Los datos de configuración están blindados: solo el administrador autenticado puede modificar los ajustes críticos del museo."

### 13. Gamificación: Sistema de Rangos (30s)
- **Mensaje:** "Para combatir la falta de retención, creamos un sistema de rangos. El usuario progresa de 'Visitante' a 'Conservador', incentivando la visita recurrente."

### 14. Pasarela de Pagos de Clase Mundial (30s)
- **Mensaje:** "El proyecto es viable y seguro. Hemos integrado **Stripe Checkout**, ofreciendo una experiencia de pago visualmente impresionante y fluida, al nivel de las plataformas de comercio electrónico líderes del mercado."

### 15. Calidad de Software y SEO (30s)
- **Mensaje:** "Aplicamos estándares profesionales: **CI/CD con GitHub Actions** para tests automáticos y un SEO técnico optimizado para visibilidad web."

### 16. Roadmap v2.0 (30s)
- **Mensaje:** "El futuro pasa por la Realidad Virtual con Meta Quest y la implementación de una guía interactiva basada en Inteligencia Artificial."

---

## Bloque 4: Conclusión (1:00 min)

### 17. Gestión y Recursos (20s)
- **Mensaje:** "Todo el desarrollo ha sido gestionado bajo metodologías ágiles, usando **Trello** para sprints y **GitHub** para el control de versiones."

### 18. Conclusión (20s)
- **Mensaje:** "La tecnología es el puente necesario para salvar la brecha entre la historia y las nuevas generaciones. El Museo Padre Suárez ya es parte del futuro."

### 19. Cierre y Preguntas (20s)
- **Mensaje:** "Muchas gracias por su atención. Estoy a su disposición para cualquier pregunta técnica que deseen realizar."
