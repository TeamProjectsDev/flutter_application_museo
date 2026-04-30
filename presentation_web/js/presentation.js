let currentSlide = 0;
const slides = document.querySelectorAll('.slide');
const progress = document.getElementById('progress');
const slideNum = document.getElementById('slideNum');

/**
 * Actualiza la visualización de la diapositiva actual y la barra de progreso
 */
function updateSlide() {
    slides.forEach((slide, index) => {
        slide.classList.toggle('active', index === currentSlide);
    });
    
    const percent = ((currentSlide + 1) / slides.length) * 100;
    progress.style.width = percent + '%';
    slideNum.innerText = `${currentSlide + 1} / ${slides.length}`;
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
 * @param {number} index - Índice de la diapositiva (0-based)
 */
function goToSlide(index) {
    if (index >= 0 && index < slides.length) {
        currentSlide = index;
        updateSlide();
    }
}

// Control por Teclado
document.addEventListener('keydown', (e) => {
    if (e.key === 'ArrowRight' || e.key === ' ') nextSlide();
    if (e.key === 'ArrowLeft') prevSlide();
});

// Inicializar la primera vista
document.addEventListener('DOMContentLoaded', updateSlide);
