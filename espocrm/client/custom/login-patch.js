require(['views/login'], LoginView => {
    const defaultData = LoginView.prototype.data;
    const defaultSetup = LoginView.prototype.setup;
    const defaultAfterRender = LoginView.prototype.afterRender;

    LoginView.prototype.data = function () {
        return {
            ...defaultData.call(this),
            applicationName: this.getConfig().get('applicationName') || 'Nexa CRM',
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
    };
});