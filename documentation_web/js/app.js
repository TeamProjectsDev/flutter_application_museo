document.addEventListener('DOMContentLoaded', () => {
    const sections = document.querySelectorAll('section');
    const navLinks = document.querySelectorAll('nav ul li a');
    const html = document.documentElement;

    // Highlight.js initialization
    document.querySelectorAll('pre code').forEach((block) => {
        hljs.highlightElement(block);
    });

    // --- SMOOTH SCROLL & ACTIVE LINK ---
    navLinks.forEach(link => {
        link.addEventListener('click', (e) => {
            const targetId = link.getAttribute('href');
            
            // Solo aplicar e.preventDefault() si es un enlace interno (empieza con #)
            if (targetId.startsWith('#')) {
                e.preventDefault();
                const targetSection = document.querySelector(targetId);
                
                if (targetSection) {
                    targetSection.scrollIntoView({
                        behavior: 'smooth'
                    });
                    
                    // Close sidebar on mobile
                    const sidebar = document.getElementById('sidebar');
                    if (sidebar && sidebar.classList.contains('open')) {
                        sidebar.classList.remove('open');
                        document.getElementById('menu-toggle').innerHTML = '☰ Menú';
                    }
                }
            }
        });
    });

    // Update active link on scroll
    window.addEventListener('scroll', () => {
        let current = '';
        
        if ((window.innerHeight + window.scrollY) >= document.body.offsetHeight - 50) {
            current = sections[sections.length - 1].getAttribute('id');
        } else {
            sections.forEach(section => {
                const sectionTop = section.offsetTop;
                if (pageYOffset >= (sectionTop - 150)) {
                    current = section.getAttribute('id');
                }
            });
        }

        if (current) {
            navLinks.forEach(link => {
                link.classList.remove('active');
                if (link.getAttribute('href') === `#${current}`) {
                    link.classList.add('active');
                }
            });
        }
    });

    // --- THEME TOGGLE ---
    const themeToggle = document.getElementById('theme-toggle');
    const savedTheme = localStorage.getItem('theme') || 'dark';
    html.setAttribute('data-theme', savedTheme);

    themeToggle.addEventListener('click', () => {
        const currentTheme = html.getAttribute('data-theme');
        const newTheme = currentTheme === 'dark' ? 'light' : 'dark';
        
        html.setAttribute('data-theme', newTheme);
        localStorage.setItem('theme', newTheme);
        
        // Animate theme toggle
        themeToggle.style.transform = 'scale(0.95)';
        setTimeout(() => {
            themeToggle.style.transform = 'scale(1)';
        }, 150);
    });

    // --- MOBILE MENU ---
    const menuToggle = document.getElementById('menu-toggle');
    const sidebar = document.getElementById('sidebar');

    if (menuToggle && sidebar) {
        menuToggle.addEventListener('click', () => {
            const isOpen = sidebar.classList.toggle('open');
            menuToggle.innerHTML = isOpen ? '✖ Cerrar' : '☰ Menú';
            menuToggle.style.transform = 'scale(0.95)';
            setTimeout(() => {
                menuToggle.style.transform = 'scale(1)';
            }, 150);
        });

        // Close sidebar when clicking outside
        document.addEventListener('click', (e) => {
            if (!sidebar.contains(e.target) && !menuToggle.contains(e.target)) {
                if (sidebar.classList.contains('open')) {
                    sidebar.classList.remove('open');
                    menuToggle.innerHTML = '☰ Menú';
                }
            }
        });
    }

    // --- BACK TO TOP ---
    const backToTop = document.getElementById('back-to-top');
    
    window.addEventListener('scroll', () => {
        if (window.scrollY > 500) {
            backToTop.classList.add('visible');
        } else {
            backToTop.classList.remove('visible');
        }
    });

    backToTop.addEventListener('click', () => {
        window.scrollTo({
            top: 0,
            behavior: 'smooth'
        });
    });

    // --- COPY CODE TO CLIPBOARD ---
    document.querySelectorAll('.code-example pre').forEach((pre) => {
        const code = pre.querySelector('code');
        const copyButton = document.createElement('button');
        copyButton.className = 'copy-code-btn';
        copyButton.innerHTML = '📋 Copiar';
        copyButton.style.cssText = `
            position: absolute;
            top: 0.5rem;
            right: 0.5rem;
            padding: 0.5rem 1rem;
            background: rgba(99, 102, 241, 0.2);
            border: 1px solid rgba(99, 102, 241, 0.4);
            border-radius: 4px;
            color: var(--text);
            cursor: pointer;
            font-size: 0.8rem;
            transition: all 0.2s;
            z-index: 10;
        `;
        
        copyButton.addEventListener('mouseover', () => {
            copyButton.style.background = 'rgba(99, 102, 241, 0.4)';
        });
        
        copyButton.addEventListener('mouseout', () => {
            copyButton.style.background = 'rgba(99, 102, 241, 0.2)';
        });
        
        copyButton.addEventListener('click', () => {
            const text = code.innerText;
            navigator.clipboard.writeText(text).then(() => {
                copyButton.innerHTML = '✓ Copiado';
                setTimeout(() => {
                    copyButton.innerHTML = '📋 Copiar';
                }, 2000);
            });
        });
        
        pre.style.position = 'relative';
        pre.appendChild(copyButton);
    });

    // --- TABLE SCROLL ON MOBILE ---
    document.querySelectorAll('.dtable').forEach((table) => {
        const wrapper = document.createElement('div');
        wrapper.style.cssText = `
            width: 100%;
            overflow-x: auto;
            -webkit-overflow-scrolling: touch;
            margin: 1rem 0;
        `;
        table.parentNode.insertBefore(wrapper, table);
        wrapper.appendChild(table);
    });

    // --- KEYBOARD SHORTCUTS ---
    document.addEventListener('keydown', (e) => {
        // Ctrl/Cmd + / para toggle menú
        if ((e.ctrlKey || e.metaKey) && e.key === '/') {
            e.preventDefault();
            menuToggle.click();
        }
        
        // Ctrl/Cmd + T para toggle tema
        if ((e.ctrlKey || e.metaKey) && e.key === 't') {
            e.preventDefault();
            themeToggle.click();
        }
        
        // Escape para cerrar menú
        if (e.key === 'Escape' && sidebar.classList.contains('open')) {
            sidebar.classList.remove('open');
            menuToggle.innerHTML = '☰ Menú';
        }
    });

    // --- INTERSECTION OBSERVER PARA ANIMACIONES ---
    const observerOptions = {
        threshold: 0.1,
        rootMargin: '0px 0px -50px 0px'
    };

    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.style.opacity = '1';
                entry.target.style.transform = 'translateY(0)';
            }
        });
    }, observerOptions);

    document.querySelectorAll('section, .card').forEach((el) => {
        el.style.opacity = '0';
        el.style.transform = 'translateY(10px)';
        el.style.transition = 'opacity 0.6s ease-out, transform 0.6s ease-out';
        observer.observe(el);
    });

});
