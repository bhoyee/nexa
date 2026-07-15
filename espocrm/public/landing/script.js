(() => {
    const header = document.querySelector('[data-header]');
    const nav = document.querySelector('[data-nav]');
    const navToggle = document.querySelector('[data-nav-toggle]');

    const updateHeader = () => {
        header?.classList.toggle('scrolled', window.scrollY > 40);
    };

    updateHeader();
    window.addEventListener('scroll', updateHeader, {passive: true});

    navToggle?.addEventListener('click', () => {
        const isOpen = nav.classList.toggle('open');
        navToggle.setAttribute('aria-expanded', String(isOpen));
        navToggle.setAttribute('aria-label', isOpen ? 'Close navigation' : 'Open navigation');
        navToggle.querySelector('span')?.classList.toggle('fa-bars', !isOpen);
        navToggle.querySelector('span')?.classList.toggle('fa-times', isOpen);
    });

    nav?.querySelectorAll('a').forEach(link => {
        link.addEventListener('click', () => {
            nav.classList.remove('open');
            navToggle?.setAttribute('aria-expanded', 'false');
            navToggle?.setAttribute('aria-label', 'Open navigation');
            navToggle?.querySelector('span')?.classList.add('fa-bars');
            navToggle?.querySelector('span')?.classList.remove('fa-times');
        });
    });

    document.querySelectorAll('[data-billing]').forEach(button => {
        button.addEventListener('click', () => {
            const billing = button.dataset.billing;
            document.querySelectorAll('[data-billing]').forEach(item => item.classList.toggle('active', item === button));
            document.querySelectorAll('[data-price]').forEach(price => {
                price.textContent = price.dataset[billing];
            });
        });
    });
})();