require(['views/site/navbar'], NavbarView => {
    const defaultData = NavbarView.prototype.data;
    const defaultAfterRender = NavbarView.prototype.afterRender;

    NavbarView.prototype.data = function () {
        const data = defaultData.call(this);

        if (!this.isSide()) {
            return data;
        }

        data.tabDefsList1 = [...data.tabDefsList1, ...data.tabDefsList2]
            .filter(item => item.name !== 'show-more')
            .map(item => ({
                ...item,
                isInMore: false,
                isAfterShowMore: false,
            }));
        data.tabDefsList2 = [];

        return data;
    };

    NavbarView.prototype.afterRender = function () {
        const result = defaultAfterRender.call(this);

        try {
            document.body.classList.toggle('nexa-side-navigation', this.isSide());

            const tenant = this.getHelper().getAppParam('nexaTenant');
            const container = this.element?.querySelector('.navbar-right-container');

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
        } catch (error) {
            console.warn('Unable to display the current workspace identity.', error);
        }

        return result;
    };
});
