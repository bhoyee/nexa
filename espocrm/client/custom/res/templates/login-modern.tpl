<main class="modern-login-shell">
    <section class="modern-login-visual" aria-label="A bright collaborative workspace">
        <div class="modern-login-brand">
            <span class="modern-login-mark" aria-hidden="true">N</span>
            <span class="modern-login-brand-name">{{applicationName}}</span>
        </div>

        <div class="modern-login-visual-copy">
            <p class="modern-login-kicker">Customer relationships, made clear</p>
            <h2>Keep every conversation moving forward.</h2>
            <p>A focused workspace for the people, opportunities, and moments that matter.</p>
        </div>
    </section>

    <section class="modern-login-auth">
        <div class="modern-login-mobile-brand">
            <span class="modern-login-mark" aria-hidden="true">N</span>
            <span class="modern-login-brand-name">{{applicationName}}</span>
        </div>

        <div id="login" class="modern-login-panel">
            <header class="modern-login-header">
                <p class="modern-login-eyebrow">Secure workspace</p>
                <h1>Welcome back</h1>
                <p>Sign in to continue to {{applicationName}}.</p>
            </header>

            <form id="login-form" class="modern-login-form">
                {{#if hasSignIn}}
                <div class="cell modern-login-provider" data-name="sign-in">
                    <button class="btn btn-default" id="sign-in" type="button">{{signInText}}</button>
                    {{#if hasFallback}}
                    <a role="button" tabindex="0" class="btn btn-link btn-icon" data-action="showFallback" title="{{translate 'Show'}}"><span class="fas fa-chevron-down"></span></a>
                    {{/if}}
                </div>
                {{/if}}

                <div class="form-group cell" data-name="username">
                    <label for="field-userName">{{translate 'Username'}}</label>
                    <div class="modern-login-input">
                        <span class="far fa-user" aria-hidden="true"></span>
                        <input type="text" name="username" id="field-userName" class="form-control" autocapitalize="off" spellcheck="false" tabindex="1" autocomplete="username" maxlength="255">
                    </div>
                </div>

                <div class="form-group cell" data-name="password">
                    <label for="field-password">{{translate 'Password'}}</label>
                    <div class="modern-login-input" data-role="password-input-container">
                        <span class="fas fa-lock" aria-hidden="true"></span>
                        <input type="password" name="password" id="field-password" class="form-control" tabindex="2" autocomplete="current-password" maxlength="255">
                        <a role="button" tabindex="0" data-action="toggleShowPassword" class="modern-login-password-toggle" title="{{translate 'View'}}"><span class="far fa-eye"></span></a>
                    </div>
                </div>

                {{#if anotherUser}}
                <div class="form-group cell modern-login-another-user">
                    <span>{{translate 'Log in as'}}</span>
                    <strong>{{anotherUser}}</strong>
                </div>
                {{/if}}

                <div class="cell modern-login-actions" data-name="submit">
                    {{#if showForgotPassword}}
                    <a role="button" class="modern-login-forgot" data-action="passwordChangeRequest" tabindex="4">{{translate 'Forgot Password?' scope='User'}}</a>
                    {{/if}}
                    <button type="submit" class="btn btn-primary" id="btn-login" tabindex="3">{{logInText}} <span class="fas fa-arrow-right" aria-hidden="true"></span></button>
                </div>
            </form>

            <p class="modern-login-security"><span class="fas fa-shield-alt" aria-hidden="true"></span>Protected access to your customer workspace</p>
        </div>
    </section>
</main>
<footer>{{{footer}}}</footer>