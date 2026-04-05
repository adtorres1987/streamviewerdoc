'use strict';

/**
 * Email template for account activation.
 * @param {string} name - User's full name
 * @param {string} code - 6-digit activation code
 * @returns {{ subject: string, html: string }}
 */
function activationEmail(name, code) {
  return {
    subject: 'Activa tu cuenta SyncPDF',
    html: `
<!DOCTYPE html>
<html lang="es">
<head><meta charset="UTF-8"><title>Activa tu cuenta</title></head>
<body style="font-family: sans-serif; color: #333; max-width: 480px; margin: 40px auto; padding: 0 20px;">
  <h2 style="color: #1a56db;">Bienvenido a SyncPDF, ${name}</h2>
  <p>Usa el siguiente código para activar tu cuenta:</p>
  <div style="font-size: 36px; font-weight: bold; letter-spacing: 8px; color: #1a56db; margin: 24px 0;">
    ${code}
  </div>
  <p style="color: #666;">Este código es válido por <strong>24 horas</strong>.</p>
  <p style="color: #999; font-size: 12px;">Si no creaste esta cuenta, ignora este email.</p>
</body>
</html>
    `.trim(),
  };
}

/**
 * Email template for password reset.
 * @param {string} name - User's full name
 * @param {string} code - 6-digit reset code
 * @returns {{ subject: string, html: string }}
 */
function resetPasswordEmail(name, code) {
  return {
    subject: 'Restablece tu contraseña en SyncPDF',
    html: `
<!DOCTYPE html>
<html lang="es">
<head><meta charset="UTF-8"><title>Restablecer contraseña</title></head>
<body style="font-family: sans-serif; color: #333; max-width: 480px; margin: 40px auto; padding: 0 20px;">
  <h2 style="color: #1a56db;">Hola, ${name}</h2>
  <p>Recibimos una solicitud para restablecer tu contraseña. Usa este código:</p>
  <div style="font-size: 36px; font-weight: bold; letter-spacing: 8px; color: #1a56db; margin: 24px 0;">
    ${code}
  </div>
  <p style="color: #666;">Este código es válido por <strong>24 horas</strong>.</p>
  <p style="color: #999; font-size: 12px;">Si no solicitaste esto, ignora este email — tu contraseña no cambiará.</p>
</body>
</html>
    `.trim(),
  };
}

/**
 * Email template for admin invitation (sent by superadmin).
 * @param {string} name - Invitee's name (or email if name unknown)
 * @param {string} link - Deep link or URL for accepting the invite
 * @returns {{ subject: string, html: string }}
 */
function adminInviteEmail(name, link) {
  return {
    subject: 'Invitación de administrador — SyncPDF',
    html: `
<!DOCTYPE html>
<html lang="es">
<head><meta charset="UTF-8"><title>Invitación de admin</title></head>
<body style="font-family: sans-serif; color: #333; max-width: 480px; margin: 40px auto; padding: 0 20px;">
  <h2 style="color: #1a56db;">Hola, ${name}</h2>
  <p>Has sido invitado a unirte a SyncPDF como <strong>administrador</strong>.</p>
  <p>Haz clic en el siguiente enlace para aceptar la invitación y crear tu cuenta:</p>
  <a href="${link}"
     style="display: inline-block; margin: 20px 0; padding: 12px 24px; background: #1a56db; color: #fff; text-decoration: none; border-radius: 6px; font-weight: bold;">
    Aceptar invitación
  </a>
  <p style="color: #666;">El enlace expira en <strong>48 horas</strong>.</p>
  <p style="color: #999; font-size: 12px;">Si no esperabas esta invitación, ignora este email.</p>
</body>
</html>
    `.trim(),
  };
}

module.exports = { activationEmail, resetPasswordEmail, adminInviteEmail };
