# Museo Histórico Padre Suárez - App 🏛️

Bienvenido al repositorio oficial de la aplicación móvil y web del **Museo Histórico Padre Suárez**. Esta aplicación ha sido desarrollada en **Flutter** y cuenta con funcionalidades avanzadas como experiencias en Realidad Aumentada (AR), modelos 3D, entornos en 360 grados, tienda de merchandising, gamificación (insignias y trofeos) y gestión de usuarios mediante Firebase.

Este documento explica paso a paso cómo configurar este proyecto desde cero, incluso si **no sabes programar**, para que puedas compilarlo y hacerlo funcionar en tu propio ordenador o publicarlo en las tiendas de aplicaciones.

---

## 📋 Índice
1. [Requisitos Previos](#1-requisitos-previos)
2. [Configuración del Archivo `.env`](#2-configuración-del-archivo-env)
3. [Configuración de Firebase (Base de Datos y Usuarios)](#3-configuración-de-firebase-base-de-datos-y-usuarios)
4. [Configuración de EmailJS (Correos Automáticos)](#4-configuración-de-emailjs-correos-automáticos)
5. [Configuración de Pagos Reales (RevenueCat y Stripe)](#5-configuración-de-pagos-reales-revenuecat-y-stripe)
6. [Configuración de Modelos 3D (GitHub Raw)](#6-configuración-de-modelos-3d-github-raw)
7. [Lanzar la Aplicación](#7-lanzar-la-aplicación)
8. [Modo Tester (Pruebas sin pagar)](#8--modo-tester-para-tribunal-y-exposiciones-sin-gasto)
9. [✨ Características de Pulido Comercial](#9--características-de-pulido-comercial)

---

## 1. Requisitos Previos

Para ejecutar este proyecto en tu ordenador, necesitas instalar:
* **[Flutter SDK](https://docs.flutter.dev/get-started/install):** El motor sobre el que está construida la app (Versión 3.24+ recomendada).
* **[Android Studio](https://developer.android.com/studio) / [Visual Studio Code](https://code.visualstudio.com/):** Para abrir el código y compilar la app.
* **Java 17+:** Necesario para las versiones modernas de Gradle y AndroidX que utiliza el proyecto.
* **Git:** Para descargar el repositorio.

---

## 2. Configuración del Archivo `.env`

La app utiliza un archivo secreto llamado `.env` para almacenar contraseñas y claves de conexión a servicios externos (Firebase, Correos, Pagos). **Este archivo NUNCA se sube a internet por seguridad.**

1. En la carpeta principal del proyecto (donde estás leyendo esto), busca un archivo llamado `.env.example`.
2. Haz una copia de ese archivo y renómbralo a **exactamente** `.env` (con el punto delante y sin nada más).
3. Abre este nuevo archivo `.env` con el Bloc de notas o tu editor de código. A continuación aprenderemos de dónde sacar cada clave para rellenarlo.

**Resumen de todas las variables:**

| Variable                       | Descripción                                       |
|--------------------------------|---------------------------------------------------|
| `FIREBASE_API_KEY`             | Clave API Firebase (Web)                          |
| `FIREBASE_APP_ID_WEB`          | App ID Firebase Web                               |
| `FIREBASE_APP_ID_ANDROID`      | App ID Firebase Android                           |
| `FIREBASE_MEASUREMENT_ID_WEB`  | ID Analytics Firebase                             |
| `FIREBASE_PROJECT_ID`          | ID del proyecto Firebase                          |
| `FIREBASE_MESSAGING_SENDER_ID` | Número de remitente Firebase                      |
| `FIREBASE_STORAGE_BUCKET`      | Bucket de almacenamiento Firebase                 |
| `EMAILJS_SERVICE_ID`           | ID de servicio EmailJS                            |
| `EMAILJS_TEMPLATE_ID`          | Plantilla EmailJS para impresiones 3D             |
| `EMAILJS_TICKET_TEMPLATE_ID`   | Plantilla EmailJS para entradas digitales         |
| `EMAILJS_USER_ID`              | Clave pública de EmailJS                          |
| `ADMIN_EMAIL`                  | Correo(s) del administrador (separados por comas) |
| `REVENUECAT_ANDROID_KEY`       | API Key RevenueCat para Android                   |
| `REVENUECAT_IOS_KEY`           | API Key RevenueCat para iOS                       |
| `STRIPE_SECRET_KEY`            | Clave secreta Stripe (formato `sk_test_...`)      |
| `GITHUB_RAW_URL`               | URL raw de GitHub para modelos 3D e imágenes 360  |
| `TESTER`                       | `1` activa el Modo Tester (ver sección 8)         |

---

## 3. Configuración de Firebase (Base de Datos y Usuarios)

Firebase es el servidor de Google que guarda los usuarios registrados, la colección de objetos que han desbloqueado y los administradores.

1. Ve a [Firebase Console](https://console.firebase.google.com/) e inicia sesión con una cuenta de Google.
2. Haz clic en **Añadir proyecto** (Ej: "Museo App").
3. Dentro del proyecto, busca la sección **Authentication** (Autenticación) en el menú izquierdo y actívala. Activa el proveedor de acceso por **Correo electrónico y contraseña**.
4. Ve a **Firestore Database** en el menú izquierdo y haz clic en **Crear base de datos** (modo producción). Dirígete a la pestaña **Reglas** y pega exactamente el siguiente código para proteger la base de datos permitiendo lectura/escritura a los usuarios registrados:
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       
       // Regla para la colección de usuarios (cada usuario lee/escribe su propio documento)
       match /users/{userId} {
         allow read, write: if request.auth != null && request.auth.uid == userId;
       }
       
       // Regla para la colección de peticiones de impresión 3D
       match /print_requests/{requestId} {
         // Cualquier usuario autenticado puede crear una petición
         allow create: if request.auth != null;
         // Un usuario solo puede leer sus propias peticiones
         allow read: if request.auth != null && request.auth.uid == resource.data.userId;
         // Solo los administradores pueden modificar el estado (Aceptada/Denegada)
         // Nota: Para un entorno real, la comprobación de admin se haría contra la colección 'users'.
         // Por simplicidad, permitimos actualización al dueño de la petición.
         allow update: if request.auth != null && (request.auth.uid == resource.data.userId);
       }
     }
   }
   ```
5. Haz clic en el icono del engranaje ⚙️ (Configuración del proyecto) arriba a la izquierda.
6. En la pestaña general, desplázate hacia abajo y añade dos aplicaciones a tu proyecto haciendo clic en los iconos:
   * **App Web:** Registra una app web. Asegúrate de marcar la casilla "Configurar Firebase Hosting" si te lo pide, pero sobre todo, al terminar te dará un bloque de código al final. Copia el `apiKey`, el `appId` y el `measurementId` (si aparece) y ponlos en tu archivo `.env` en los apartados `FIREBASE_API_KEY_WEB`, `FIREBASE_APP_ID_WEB` y `FIREBASE_MEASUREMENT_ID_WEB`. Esto activará las analíticas web.
   * **App Android:** Registra una app Android (el nombre del paquete suele ser `com.example.flutter_application_museo` o el que aparezca en `android/app/build.gradle`). Al terminar, la web te dará una clave API de Android y un ID de App. Pégalos en `FIREBASE_API_KEY_ANDROID` y `FIREBASE_APP_ID_ANDROID`.
7. En esa misma página de configuración, busca y copia el "ID de proyecto" (`FIREBASE_PROJECT_ID`), el "Número de remitente" (`FIREBASE_MESSAGING_SENDER_ID`) y el "Depósito de almacenamiento" (`FIREBASE_STORAGE_BUCKET`). Pégalos en tu `.env`.

### 📊 Eventos de Analíticas Integrados
La app está preconfigurada de fábrica para enviar estadísticas de uso super completas a la pestaña **Analytics** de Firebase. Recopila automáticamente de Web, iOS y Android:

* **Eventos de Sistema (Automáticos):** Firebase rastrea instalaciones (`first_open`), desinstalaciones en Android (`app_remove`), actualizaciones de la app (`app_update`) y tiempo de uso de la sesión (`user_engagement`).
* **Páginas Vistas (Automático):** Sabrás qué pantallas se visitan más gracias al rastreador de `GoRouter`.
* **Usuarios (`logLogin` / `logSignUp`):** Registra si la gente entra como anónimo o con correo.
* **AR y Escáner (`ar_scan_...`):**
  * `ar_scan_success`: Registra qué pieza exacta de la exhibición es más popular usando su ID.
  * `ar_scan_error`: Te avisa si la gente escanea códigos erróneos o ajenos al museo.
  * `ar_scan_simulated`: Separa los escaneos de prueba que haces desde el simulador de PC.
* **Exploración 3D y VR (`view_item_...`):**
  * `view_item_3d`: Cuando cargan con éxito un modelo en el visor AR interactivo.
  * `view_item_360`: Cuando abren un entorno inmersivo VR.
* **Conversión y Tienda (`add_to_cart`, `_success`, `_error`):**
  * `add_to_cart`: Guardará qué reproducciones físicas piden mediante el formulario del apartado Merchandising.
  * `donation_..._success` / `ticket_..._success`: Sabrás si el usuario completó el flujo de pago con éxito usando dinero de verdad (`revenuecat` o `stripe`) o si fue una demo (`mock`).
  * `ecommerce_error`: Se dispara de forma invisible si hay fallos en Firestore guardando un pedido físico.

**🔐 ¿Cómo ser Administrador?**
Abre la base de datos Firestore, busca la colección `users`, encuentra tu propio usuario (su identificador largo) y asegúrate de que tiene un campo llamado `role` con el texto exactamente igual a `admin`.

---

## 4. Configuración de EmailJS (Correos Automáticos)

La app envía correos reales (tickets digitales, avisos de impresión 3D) a los usuarios sin necesidad de un servidor complejo. Usamos **EmailJS**.

1. Regístrate gratis en [EmailJS.com](https://www.emailjs.com/).
2. En la pestaña **Email Services**, añade tu correo electrónico personal (por ejemplo, Gmail) para que la app envíe correos a través de él. Te dará un `Service ID`. Pégalo en el `.env` en `EMAILJS_SERVICE_ID`.
3. En **Email Templates**, crea dos plantillas:
   * **Plantilla 1 (Peticiones 3D):** Crea una plantilla que reciba variables web. Anota su "Template ID" en `EMAILJS_TEMPLATE_ID`.
     * **Ejemplo de contenido de la plantilla:**
       ```html
       Asunto: Solicitud de Impresión 3D: {{object_name}}
       
       Hola equipo,
       El usuario {{user_email}} ha solicitado la impresión 3D del objeto: {{object_name}}.
       Fecha de la solicitud: {{request_date}}
       ```
   * **Plantilla 2 (Entradas Digitales):** Crea otra plantilla para los códigos QR. Anota su "Template ID" en `EMAILJS_TICKET_TEMPLATE_ID`.
     * **Ejemplo de contenido de la plantilla:**
       ```html
       Asunto: Tu Entrada Digital - Museo Histórico Padre Suárez
       
       ¡Hola! Gracias por tu compra.
       Aquí tienes el identificador único de tu entrada digital:
       {{ticket_code}}
       
       Muéstralo en la puerta de acceso al recinto.
       (Comprado el: {{purchase_date}})
       ```
4. Ve a la pestaña **Account** arriba a la derecha para ver tu "Public Key". Ese es tu `EMAILJS_USER_ID` para el `.env`.

---

## 5. Configuración de Pagos Reales (RevenueCat y Stripe)

La aplicación tiene un sistema **híbrido** inteligente para abarcar a todos los usuarios: utiliza **RevenueCat** para las compras dentro de tu móvil (Android/iOS) usando las billeteras nativas, y utiliza una integración a medida con la API de **Stripe** para simuladores en PC o versiones Web (donde RevenueCat no llega por defecto).

### A) Configuración Móvil (RevenueCat)
1. Crea una cuenta en [RevenueCat](https://www.revenuecat.com/).
2. Crea un nuevo proyecto.
3. RevenueCat te pedirá que lo vincules con tus cuentas comerciales reales de [Google Play Console](https://play.google.com/console) (cuesta 25$) y App Store Connect (cuesta 99$/año). *Puedes saltarte este paso provisionalmente si solo vas a hacer pruebas de tribunales enseñando la simulación.*
4. Cuando crees la app de Android dentro de RevenueCat, te dará una API Key. Ponla en el archivo `.env` en `REVENUECAT_ANDROID_KEY`.
5. Si creas la app de iOS, te dará otra clave paralela. Ponla en `REVENUECAT_IOS_KEY`.
6. En Google Play/AppStore, asegúrate de crear los identificadores exactos para los productos In-App (por ejemplo, `donacion_bronce`, `donacion_plata`, `donacion_oro`), de lo contrario la app dirá que los productos no se encuentran al cobrar.

### B) Configuración PC / Web (Stripe)
Si el museo se exporta a Web o se instala en el PC de la entrada, RevenueCat no puede procesar los pagos. Para esto hemos integrado la API dinámica de Stripe.
1. Crea una cuenta gratuita en [Stripe.com](https://stripe.com/).
2. Accede a tu Panel de Control (Dashboard) y haz clic en la esquina superior derecha donde dice **"Desarrolladores"** o **"Laves API"** (API Keys).
3. Asegúrate de tener activado el "Modo de Prueba" (un interruptor arriba a la derecha) para poder hacer compras falsas.
4. En la pestaña de llaves API, busca tu **Clave secreta** (Secret Key). Tiene este formato: `sk_test_...`
5. Cópiala y pégala en tu archivo `.env` justo aquí:
   ```env
   STRIPE_SECRET_KEY=sk_test_abcd...
   ```
¡Y ya está! La aplicación detectará automáticamente cuando un usuario esté usando un PC y generará una plataforma de pago virtual *al vuelo* redirigiéndole para proteger las tarjetas, avisando al vuelo del éxito para enviarle su Ticket por correo.

---

## 6. Configuración de Modelos 3D (GitHub Raw)

La app descarga los modelos 3D (`.glb`) en tiempo real desde un servidor externo para que tu móvil no pese gigabytes. Por defecto apuntará al repositorio central del museo en GitHub.

* `GITHUB_RAW_URL`: Debe apuntar siempre a la rama *raw* de GitHub, por ejemplo: `https://raw.githubusercontent.com/TU_USUARIO/TU_REPOSITORIO/main`. Las carpetas deben contener las imágenes y fondos.

---

## 7. Lanzar la Aplicación

¡Ya has rellenado todo! Es hora de abrir la app.

1. Abre la terminal (`CMD` o la terminal de Visual Studio Code) en la carpeta raíz del proyecto.
2. Descarga todas las librerías necesarias ejecutando:
   ```bash
   flutter pub get
   ```
3. Conecta tu teléfono móvil por cable (con el modo de depuración USB activado) o abre el simulador de Chrome/Android Studio.
4. Pulsa en Run (F5) en tu editor, o ejecuta en la terminal:
   ```bash
   flutter run
   ```
*(La primera vez tardará varios minutos en descargar recursos. ¡Ten paciencia!)*

---

## 8. 🎮 MODO TESTER (Para Tribunal y Exposiciones sin Gasto)

Si estás mostrando esta app a un tribunal, amigos o en una feria y **no quieres que salten pantallas de tarjetas de crédito reales** ni quieres caminar físicamente por un museo para escanear AR, tienes un "Modo Dios" que he programado.

En tu archivo `.env`, cambia la última línea:
```env
TESTER=1
```

**¿Qué hace el modo Tester (`TESTER=1`)?**
* Añade un botón rápido en la cámara AR (`ar_screen.dart`) que simula que has escaneado exitosamente un código, para que puedas ver el objeto 3D sin moverte de la silla.
* Al donar dinero o comprar merchandising, se simula una compra exitosa (aparece una barra verde) sin tocar RevenueCat, AppStore ni tarjetas de crédito, por lo que puedes demostrar todo el flujo de compra tranquilamente en público.
* Desbloquea todos los visores de candados de la Galería 3D.
* Muestra un letrero amarillo de "TESTER" arriba a la derecha.

Cuando vayas a subir la App a Google Play (Producción) para la gente real en la calle, **recuerda cambiarlo a `TESTER=0`** y la app pasará a funcionar con pasarelas de bancos reales y códigos QR obligatorios.

---

## 9. ✨ Características de Pulido Comercial

Esta aplicación no es un simple prototipo; incluye funcionalidades de nivel de producción comercial listas para distribuirse en las tiendas de apps:

* **🎨 Icono de Aplicación y Splash Screen:** La app cuenta con un icono nativo diseñado específicamente para el museo y una pantalla de carga (Splash Screen) personalizada que se muestra mientras el motor de Flutter se inicializa, dando una impresión instantánea de máxima profesionalidad.

* **📖 Onboarding (Tutorial de Bienvenida):** Los nuevos usuarios son recibidos con un tutorial de bienvenida (deslizable) que explica las funciones principales del museo (AR, 3D, Gamificación). Este progreso se guarda en el teléfono para que solo aparezca la primera vez.

* **🌍 Multidioma Reactivo (i18n):** La interfaz completa está traducida a Español e Inglés con un sistema de alta fidelidad. 
  * **Persistencia Real:** La app recuerda el idioma incluso antes de mostrar la primera pantalla, leyendo directamente de las preferencias del sistema antes del arranque (`runApp`).
  * **Cambio en Caliente:** El usuario puede cambiar de idioma desde Ajustes y toda la aplicación se redibuja al instante sin parpadeos ni errores de navegación, gracias a una arquitectura reactiva con `riverpod` y `easy_localization`.
  * **Cobertura:** Los archivos `en.json` y `es.json` cubren más de 150 etiquetas, asegurando que no queden textos sin traducir.

* **💰 Gamificación — Sistema de Rangos:** A medida que el usuario desbloquea piezas escaneando, sube de rango:
  | Rango            | Piezas | Color |
  |------------------|--------|-------|
  | Visitante        | 0      | Gris  |
  | Explorador       | 1–2    | Bronce|
  | Académico        | 3–5    | Plata |
  | Conservador Jefe | 6+     | Oro   |
  El rango aparece en la pantalla de perfil y en el inicio.

* **📰 Bio-Revista Científica:** Sección de noticias con feeds RSS en tiempo real de fuentes científicas (Agencia SINC y otras). Las imágenes se almacenan en caché local con `cached_network_image` — la segunda visita carga instantáneamente sin red.

* **🗺️ Mapa Interactivo del Museo:** Plano de planta interactivo dibujado con `CustomPainter`. Cada sala tiene un hotspot pulsable que muestra su descripción y permite navegar directamente a las piezas de esa sala.

* **💳 Pagos Híbridos Universales (Stripe + RevenueCat):** Implementa lógica responsiva de pasarela de pagos. Los usuarios en ecosistemas móviles cerrados pagarán por Google/Apple Pay usando RevenueCat, mientras que los visitantes desde ordenador o web tendrán acceso a URLs dinámicas (Checkout Sessions) de Stripe.

* **📈 Analíticas Multiplataforma (Firebase):** Seguimiento del comportamiento de los usuarios (visitas a pantallas, compras de entradas en Stripe, donaciones simuladas o reales) con soporte total para Android, iOS y Web.

---

### 🛠️ Nota Técnica: Entorno de Compilación
Este proyecto ha sido actualizado para cumplir con los estándares de seguridad y rendimiento de 2024/2025:
* **Gradle:** 8.11.1
* **Android Gradle Plugin (AGP):** 8.9.1
* **Kotlin:** 2.1.0
* **Seguridad:** El archivo `.env` está estrictamente ignorado por Git. Se incluye un `.env.example` como plantilla.
* **Optimizaciones:** Se han eliminado dependencias obsoletas como `arcore_flutter_plugin` para garantizar la compatibilidad con las últimas versiones de AndroidX y Gradle, delegando la AR de forma más eficiente al visor nativo.
