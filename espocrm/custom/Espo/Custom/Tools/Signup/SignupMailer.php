<?php

namespace Espo\Custom\Tools\Signup;

use Espo\Core\Mail\EmailSender;
use Espo\Core\Tenant\TenantContext;
use Espo\Core\Tenant\TenantContextStore;
use Espo\Core\Utils\Log;
use Espo\Entities\Email;
use Espo\ORM\EntityManager;
use Throwable;

/**
 * Sends tenant-branded verification mail inside the new tenant context.
 * Delivery failures are reported to SignupService instead of invalidating the
 * already-committed pending workspace.
 */
final class SignupMailer
{
    public function __construct(
        private EntityManager $entityManager,
        private EmailSender $emailSender,
        private TenantContextStore $tenantContextStore,
        private Log $log,
    ) {}

    public function sendVerification(
        string $tenantId,
        string $slug,
        string $company,
        string $firstName,
        string $address,
        string $verificationCode,
    ): bool {
        if (!$this->emailSender->hasSystemSmtp()) {
            return false;
        }

        // Email entities are tenant-owned, so even pre-activation messages must
        // be created under the tenant they belong to.
        try {
            return $this->tenantContextStore->runWith(
                new TenantContext($tenantId, $slug, 'self-service-signup', $company),
                function () use ($company, $firstName, $address, $verificationCode): bool {
                    /** @var Email $email */
                    $email = $this->entityManager->getNewEntity(Email::ENTITY_TYPE);
                    $name = htmlspecialchars($firstName !== '' ? $firstName : 'there', ENT_QUOTES, 'UTF-8');
                    $workspace = htmlspecialchars($company, ENT_QUOTES, 'UTF-8');
                    $code = htmlspecialchars($verificationCode, ENT_QUOTES, 'UTF-8');
                    $body = '<p>Hello ' . $name . ',</p>' .
                        '<p>Enter this code to activate <strong>' . $workspace . '</strong>:</p>' .
                        '<p><strong>' . $code . '</strong></p>' .
                        '<p>This code expires in 15 minutes. Never share it with anyone.</p>';

                    $email
                        ->setSubject('Verify your Nexa CRM workspace')
                        ->setBody($body)
                        ->setIsHtml(true)
                        ->addToAddress($address);

                    $this->emailSender->send($email);
                    return true;
                }
            );
        } catch (Throwable $e) {
            $this->log->error('Nexa signup verification email failed: ' . $e->getMessage());
            return false;
        }
    }
}
