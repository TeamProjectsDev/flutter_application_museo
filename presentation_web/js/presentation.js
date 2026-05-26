let currentSlide = 0;
const slides = document.querySelectorAll('.slide');
const progress = document.getElementById('progress');
const currentSlideEl = document.getElementById('current-slide');
const totalSlidesEl = document.getElementById('total-slides');
const tocDrawer = document.getElementById('tocDrawer');
const tocOverlay = document.getElementById('tocOverlay');
const tocContent = document.getElementById('tocContent');

/**
 * Actualiza la visualización de la diapositiva actual, la barra de progreso y el índice activo
 */
function updateSlide() {
    slides.forEach((slide, index) => {
        slide.classList.toggle('active', index === currentSlide);
    });
    
    // Actualizar barra de progreso
    if (progress) {
        const percent = ((currentSlide + 1) / slides.length) * 100;
        progress.style.width = percent + '%';
    }
    
    // Actualizar números de slide
    if (currentSlideEl) currentSlideEl.innerText = currentSlide + 1;
    if (totalSlidesEl) totalSlidesEl.innerText = slides.length;

    // Resaltar elemento activo en el TOC
    const tocItems = document.querySelectorAll('.toc-drawer-item');
    tocItems.forEach((item, index) => {
        item.classList.toggle('active', index === currentSlide);
    });
}

/**
 * Avanza a la siguiente diapositiva
 */
function nextSlide() {
    if (currentSlide < slides.length - 1) {
        currentSlide++;
        updateSlide();
    }
}

/**
 * Retrocede a la diapositiva anterior
 */
function prevSlide() {
    if (currentSlide > 0) {
        currentSlide--;
        updateSlide();
    }
}

/**
 * Salta directamente a una diapositiva específica
 * @param {number} slideNumber - Número de la diapositiva (1-based)
 */
function goToSlide(slideNumber) {
    const index = slideNumber - 1;
    if (index >= 0 && index < slides.length) {
        currentSlide = index;
        updateSlide();
    }
}

/**
 * Muestra/oculta el menú lateral del índice (TOC)
 */
function toggleTableOfContents() {
    const isOpen = tocDrawer.classList.contains('open');
    if (isOpen) {
        tocDrawer.classList.remove('open');
        tocOverlay.classList.remove('active');
    } else {
        tocDrawer.classList.add('open');
        tocOverlay.classList.add('active');
    }
}

/**
 * Genera dinámicamente el contenido del índice lateral (TOC)
 */
function generateTOC() {
    if (!tocContent) return;
    tocContent.innerHTML = '';
    
    slides.forEach((slide, index) => {
        // Buscar el título del slide (priorizar h2, usar h1 como fallback para portada)
        const header = slide.querySelector('h2') || slide.querySelector('h1');
        let titleText = `Diapositiva ${index + 1}`;
        
        if (header) {
            // Limpiar texto de saltos de línea y formatear
            titleText = header.textContent.replace(/\r?\n|\r/g, ' ').trim();
            // Evitar títulos extremadamente largos en el índice
            if (titleText.length > 40) {
                titleText = titleText.substring(0, 37) + '...';
            }
        }
        
        const item = document.createElement('div');
        item.className = 'toc-drawer-item';
        if (index === currentSlide) {
            item.classList.add('active');
        }
        
        item.innerHTML = `
            <span class="toc-drawer-num">${String(index + 1).padStart(2, '0')}</span>
            <span class="toc-drawer-title">${titleText}</span>
        `;
        
        item.addEventListener('click', () => {
            goToSlide(index + 1);
            toggleTableOfContents();
        });
        
        tocContent.appendChild(item);
    });
}

// Control por Teclado
document.addEventListener('keydown', (e) => {
    // Evitar navegación si se está interactuando con algún input (si existiese)
    if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA') return;
    
    if (e.key === 'ArrowRight' || e.key === ' ') {
        e.preventDefault();
        nextSlide();
    }
    if (e.key === 'ArrowLeft') {
        e.preventDefault();
        prevSlide();
    }
    if (e.key.toLowerCase() === 't') {
        e.preventDefault();
        toggleTableOfContents();
    }
});

// Inicializar la presentación al cargar la página
document.addEventListener('DOMContentLoaded', () => {
    generateTOC();
    updateSlide();
});
