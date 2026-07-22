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
                <div class="modern-social-providers" data-auth-providers hidden aria-label="Social account sign in"></div>
                <div class="modern-auth-divider" data-auth-divider hidden><span>or continue with your account</span></div>
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
                    <a role="button" class="modern-login-forgot" data-action="nexaRecovery" tabindex="4">{{translate 'Forgot Password?' scope='User'}}</a>
                    {{/if}}
                    <button type="submit" class="btn btn-primary" id="btn-login" tabindex="3">{{logInText}} <span class="fas fa-arrow-right" aria-hidden="true"></span></button>
                </div>
            </form>

            <p class="modern-create-account">New to Nexa? <a href="/?signup=growth">Create an account</a></p>
            <p class="modern-login-security"><span class="fas fa-shield-alt" aria-hidden="true"></span>Protected access to your customer workspace</p>
        </div>

        <div class="modern-login-panel modern-recovery-panel" data-recovery-panel hidden>
            <button class="modern-back-button" type="button" data-recovery-back><span class="fas fa-arrow-left" aria-hidden="true"></span> Back to sign in</button>
            <header class="modern-login-header">
                <p class="modern-login-eyebrow">Account recovery</p>
                <h1>Reset your password</h1>
                <p>Enter the username and email used for your workspace.</p>
            </header>
            <form class="modern-login-form" data-recovery-form novalidate>
                <div class="modern-recovery-message" data-recovery-message role="status" aria-live="polite" hidden></div>
                <div class="form-group">
                    <label for="recovery-username">Username</label>
                    <div class="modern-login-input"><span class="far fa-user" aria-hidden="true"></span><input class="form-control" id="recovery-username" name="username" autocomplete="username" maxlength="255" required></div>
                </div>
                <div class="form-group">
                    <label for="recovery-email">Email address</label>
                    <div class="modern-login-input"><span class="far fa-envelope" aria-hidden="true"></span><input class="form-control" id="recovery-email" name="email" type="email" autocomplete="email" maxlength="190" required></div>
                </div>
                <button class="btn btn-primary modern-submit" type="submit"><span>Send reset instructions</span></button>
            </form>
        </div>
    </section>
</main>
<footer>{{{footer}}}</footer>
