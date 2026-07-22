require(['views/login', 'views/user/password-change-request'], (LoginView, PasswordResetView) => {
    const defaultData = LoginView.prototype.data;
    const defaultSetup = LoginView.prototype.setup;
    const defaultAfterRender = LoginView.prototype.afterRender;
    const defaultResetSetup = PasswordResetView.prototype.setup;

    LoginView.prototype.data = function () {
        return {
            ...defaultData.call(this),
            applicationName: 'Nexa CRM',
            // Nexa owns recovery through its tenant-aware endpoint, so the entry
            // point must not depend on EspoCRM's legacy SMTP-derived UI flag.
            showForgotPassword: true,
        };
    };

    LoginView.prototype.setup = function () {
        this.template = 'custom:login-modern';
        defaultSetup.call(this);

        this.once('remove', () => {
            document.body.classList.remove('modern-login-page');
        });
    };

    LoginView.prototype.afterRender = function () {
        defaultAfterRender.call(this);
        document.body.classList.add('modern-login-page');

        const loginPanel = this.element.querySelector('#login');
        const recoveryPanel = this.element.querySelector('[data-recovery-panel]');
        const recoveryForm = this.element.querySelector('[data-recovery-form]');
        const recoveryMessage = this.element.querySelector('[data-recovery-message]');
        const showLogin = () => {
            recoveryPanel.hidden = true;
            loginPanel.hidden = false;
            window.setTimeout(() => this.element.querySelector('#field-userName')?.focus(), 0);
        };
        // OAuth returns the short-lived Espo token in the URL fragment so it is
        // never sent in referrers or server access logs.
        const socialPayload = location.hash.startsWith('#nexa-social=')
            ? location.hash.slice('#nexa-social='.length)
            : null;
        if (socialPayload) {
            history.replaceState(null, '', location.pathname + location.search);
            try {
                const padded = socialPayload.replace(/-/g, '+').replace(/_/g, '/')
                    .padEnd(Math.ceil(socialPayload.length / 4) * 4, '=');
                const social = JSON.parse(decodeURIComponent(escape(atob(padded))));
                const authorization = btoa(social.userName + ':' + social.token);
                this.disableForm();
                Espo.Ajax.getRequest('App/user', null, {
                    login: true,
                    headers: {
                        Authorization: 'Basic ' + authorization,
                        'Espo-Authorization': authorization,
                        'Espo-Authorization-By-Token': 'true',
                    },
                }).then(data => this.triggerLogin(social.userName, data))
                    .catch(() => {
                        this.undisableForm();
                        const message = this.element.querySelector('[data-login-message]');
                        message.textContent = 'Google sign in could not be completed. Please try again.';
                        message.hidden = false;
                    });
            } catch (error) {
                const message = this.element.querySelector('[data-login-message]');
                message.textContent = 'Google sign in could not be completed. Please try again.';
                message.hidden = false;
            }
        }
        const socialError = new URLSearchParams(location.search).get('socialError');
        if (socialError) {
            const message = this.element.querySelector('[data-login-message]');
            message.textContent = socialError === 'social_account_not_linked'
                ? 'No Nexa account is connected to that Google account. Create a workspace first.'
                : 'Google sign in was cancelled or could not be completed.';
            message.hidden = false;
        }

        this.element.querySelector('[data-action="nexaRecovery"]')?.addEventListener('click', event => {
            event.preventDefault();
            loginPanel.hidden = true;
            recoveryPanel.hidden = false;
            window.setTimeout(() => recoveryForm.elements.username.focus(), 0);
        });
        this.element.querySelector('[data-recovery-back]')?.addEventListener('click', showLogin);
        if (new URLSearchParams(location.search).get('recovery') === '1') {
            loginPanel.hidden = true;
            recoveryPanel.hidden = false;
            window.setTimeout(() => recoveryForm.elements.username.focus(), 0);
        }

        recoveryForm?.addEventListener('submit', async event => {
            event.preventDefault();
            if (!recoveryForm.reportValidity()) return;
            const submit = recoveryForm.querySelector('[type="submit"]');
            submit.disabled = true;
            recoveryMessage.hidden = true;
            try {
                const response = await fetch('/api/v1/Nexa/auth/recovery', {
                    method: 'POST',
                    credentials: 'same-origin',
                    headers: {'Content-Type': 'application/json'},
                    body: JSON.stringify(Object.fromEntries(new FormData(recoveryForm))),
                });
                const body = await response.json().catch(() => ({}));
                recoveryMessage.textContent = response.ok
                    ? body.message
                    : body.message || 'We could not process the request. Try again.';
                recoveryMessage.classList.toggle('error', !response.ok);
                recoveryMessage.hidden = false;
                if (response.ok) recoveryForm.reset();
            } catch (error) {
                recoveryMessage.textContent = 'We could not process the request. Try again.';
                recoveryMessage.classList.add('error');
                recoveryMessage.hidden = false;
            } finally {
                submit.disabled = false;
            }
        });

        fetch('/api/v1/Nexa/auth/providers', {credentials: 'same-origin'})
            .then(response => response.ok ? response.json() : {providers: []})
            .then(({providers = []}) => {
                const target = this.element.querySelector('[data-auth-providers]');
                const divider = this.element.querySelector('[data-auth-divider]');
                if (!target || providers.length === 0) return;
                providers.forEach(provider => {
                    const button = document.createElement('button');
                    button.type = 'button';
                    button.className = 'modern-social-button';
                    button.innerHTML = '<span class="fab fa-' + provider.icon + '" aria-hidden="true"></span><span>Continue with ' + provider.label + '</span>';
                    button.addEventListener('click', () => {
                        const url = new URL(provider.startUrl, location.origin);
                        url.searchParams.set('intent', 'login');
                        location.assign(url);
                    });
                    target.append(button);
                });
                target.hidden = false;
                divider.hidden = false;
            })
            .catch(() => {});
    };

    PasswordResetView.prototype.setup = function () {
        this.template = 'custom:password-reset';
        defaultResetSetup.call(this);
        document.body.classList.add('modern-login-page', 'modern-reset-page');
        this.once('remove', () => document.body.classList.remove('modern-login-page', 'modern-reset-page'));
    };
});
