<?php

namespace Espo\Custom\Tools\Signup;

use Espo\Core\Mail\EmailSender;
use Espo\Core\Tenant\TenantContextStore;
use Espo\Core\Utils\Log;
use Espo\Entities\Email;
use Espo\ORM\EntityManager;
use Throwable;

/** Sends verification before a tenant exists through the global system sender. */
final class SignupMailer
{
    public function __construct(
        private EntityManager $entityManager,
        private EmailSender $emailSender,
        private TenantContextStore $tenantContextStore,
        private Log $log,
    ) {}

    public function sendVerification(string $company, string $firstName, string $address, string $verificationCode): bool
    {
        if (!$this->emailSender->hasSystemSmtp()) return false;
        try {
            return $this->tenantContextStore->runAsPlatform(function () use ($company, $firstName, $address, $verificationCode): bool {
                /** @var Email $email */
                $email = $this->entityManager->getNewEntity(Email::ENTITY_TYPE);
                $name = htmlspecialchars($firstName !== '' ? $firstName : 'there', ENT_QUOTES, 'UTF-8');
                $workspace = htmlspecialchars($company, ENT_QUOTES, 'UTF-8');
                $code = htmlspecialchars($verificationCode, ENT_QUOTES, 'UTF-8');
                $body = '<p>Hello ' . $name . ',</p><p>Enter this code to verify your email and finish creating <strong>' . $workspace . '</strong>:</p>' .
                    '<p style="font-size:28px;font-weight:700;letter-spacing:4px">' . $code . '</p>' .
                    '<p>This code expires in 15 minutes. Never share it with anyone.</p>';
                $email->setSubject('Verify your Nexa CRM email')->setBody($body)->setIsHtml(true)->addToAddress($address);
                $this->emailSender->send($email);
                return true;
            });
        } catch (Throwable $e) {
            $this->log->error('Nexa signup verification email failed: ' . $e->getMessage());
            return false;
        }
    }
}