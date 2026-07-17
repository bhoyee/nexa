require(['views/site/navbar'], NavbarView => {
    const defaultData = NavbarView.prototype.data;
    const defaultAfterRender = NavbarView.prototype.afterRender;
    const plannedModuleGroups = [
        {
            name: 'nexa-marketing-suite',
            label: 'Marketing Suite',
            iconClass: 'fas fa-bullhorn',
            modules: [
                ['nexa-forms-content', 'Consent, Forms & Content'],
                ['nexa-marketing-contacts', 'Marketing Contacts & Events'],
                ['nexa-marketing-email', 'Marketing Email'],
                ['nexa-tracking-events', 'Tracking & Events'],
                ['nexa-automation', 'Automation'],
                ['nexa-scoring-abm', 'Scoring, Personalization & ABM'],
                ['nexa-experiments', 'Experiments'],
            ],
        },
        {
            name: 'nexa-customer-engagement',
            label: 'Customer Engagement',
            iconClass: 'fas fa-comments',
            modules: [
                ['nexa-conversations', 'Conversations & Bots'],
                ['nexa-messaging', 'SMS & WhatsApp'],
                ['nexa-social', 'Social Workspace'],
                ['nexa-advertising', 'Advertising'],
            ],
        },
        {
            name: 'nexa-intelligence',
            label: 'Intelligence',
            iconClass: 'fas fa-chart-line',
            modules: [
                ['nexa-seo-content', 'SEO & Content Intelligence'],
                ['nexa-analytics', 'Analytics & Attribution'],
                ['nexa-ai-services', 'AI Services'],
            ],
        },
        {
            name: 'nexa-platform',
            label: 'Platform',
            iconClass: 'fas fa-layer-group',
            modules: [
                ['nexa-saas-admin', 'SaaS Administration'],
                ['nexa-access-security', 'Access & Security'],
                ['nexa-integrations', 'Enterprise Integrations'],
                ['nexa-support-operations', 'Support Operations'],
            ],
        },
    ];

    const createPlannedModule = ([name, label]) => ({
        name,
        label,
        shortLabel: label.substring(0, 2),
        link: null,
        isGroup: false,
        isDivider: false,
        isInMore: false,
        isAfterShowMore: false,
        aClassName: 'nexa-planned-module-link',
    });

    const createPlannedGroup = group => ({
        name: group.name,
        label: group.label,
        shortLabel: group.label.substring(0, 2),
        link: null,
        iconClass: group.iconClass,
        isGroup: true,
        isDivider: false,
        isInMore: false,
        isAfterShowMore: false,
        aClassName: 'nav-link-group nexa-planned-group-link',
        itemList: group.modules.map(createPlannedModule),
    });

    NavbarView.prototype.data = function () {
        const data = defaultData.call(this);

        if (!this.isSide()) {
            return data;
        }

        const existingTabs = [...data.tabDefsList1, ...data.tabDefsList2]
            .filter(item => item.name !== 'show-more')
            .map(item => ({
                ...item,
                isInMore: false,
                isAfterShowMore: false,
            }));
        const nexaDivider = {
            name: 'nexa-modules-divider',
            label: 'Nexa Modules',
            isDivider: true,
            isGroup: false,
            isInMore: false,
            isAfterShowMore: false,
            aClassName: 'nav-divider-text',
        };

        data.tabDefsList1 = [
            ...existingTabs,
            nexaDivider,
            ...plannedModuleGroups.map(createPlannedGroup),
        ];
        data.tabDefsList2 = [];

        return data;
    };

    NavbarView.prototype.afterRender = function () {
        const result = defaultAfterRender.call(this);

        try {
            document.body.classList.toggle('nexa-side-navigation', this.isSide());

            this.element
                ?.querySelectorAll('.nexa-planned-module-link')
                .forEach(link => {
                    const label = link.querySelector('.full-label')?.textContent?.trim() || 'Module';

                    link.setAttribute('aria-disabled', 'true');
                    link.setAttribute('aria-label', `${label}, planned module`);
                    link.title = 'Planned module';

                    const indicator = document.createElement('span');
                    indicator.className = 'fas fa-clock nexa-planned-module-indicator';
                    indicator.setAttribute('aria-hidden', 'true');
                    link.append(indicator);
                    link.addEventListener('click', event => {
                        event.preventDefault();
                        event.stopImmediatePropagation();
                    });
                });

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
            console.warn('Unable to enhance the tenant workspace navigation.', error);
        }

        return result;
    };
});
