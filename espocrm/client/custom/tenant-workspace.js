require(['views/site/navbar'], NavbarView => {
    const defaultAfterRender = NavbarView.prototype.afterRender;

    NavbarView.prototype.afterRender = function () {
        const result = defaultAfterRender.call(this);
        const tenant = this.getAppParam('nexaTenant');
        const container = this.element.querySelector('.navbar-right-container');

        if (!tenant || !container) {
            return result;
        }

        container.querySelector('.nexa-tenant-identity')?.remove();

        const displayName = tenant.displayName || tenant.slug;
        const initials = displayName
            .split(/\s+/)
            .filter(Boolean)
            .slice(0, 2)
            .map(part => part.charAt(0).toUpperCase())
            .join('');
        const identity = document.createElement('div');
        const mark = document.createElement('span');
        const copy = document.createElement('span');
        const label = document.createElement('span');
        const name = document.createElement('strong');

        identity.className = 'nexa-tenant-identity';
        identity.dataset.tenantId = tenant.id;
        identity.title = `Current workspace: ${displayName}`;
        identity.setAttribute('aria-label', identity.title);

        mark.className = 'nexa-tenant-mark';
        mark.textContent = initials || 'N';
        copy.className = 'nexa-tenant-copy';
        label.className = 'nexa-tenant-label';
        label.textContent = 'Workspace';
        name.className = 'nexa-tenant-name';
        name.textContent = displayName;

        copy.append(label, name);
        identity.append(mark, copy);
        container.prepend(identity);
        document.body.dataset.tenantSlug = tenant.slug;

        return result;
    };
});