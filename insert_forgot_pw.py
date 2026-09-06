import re

auth_path = "/home/yaqingo/yaqin-production/backend/routers/auth.py"

with open(auth_path, "r") as f:
    content = f.read()

# Fix import
content = content.replace(
    "MasterProfileCreate, SubscriptionResponse, FCMTokenUpdate, SendCodeRequest\n)",
    "MasterProfileCreate, SubscriptionResponse, FCMTokenUpdate, SendCodeRequest,\n    ResetPasswordRequest\n)"
)

new_endpoints = '''

@router.post("/forgot-password/send-code", response_model=MessageResponse)
async def forgot_password_send_code(data: SendCodeRequest, db: Session = Depends(get_db)):
    clean_phone = normalize_phone_number(data.phone)
    
    existing = db.query(User).filter(User.phone == clean_phone).first()
    if not existing:
        all_users = db.query(User).all()
        for u in all_users:
            if normalize_phone_number(u.phone) == clean_phone:
                existing = u
                break
    
    if not existing:
        raise HTTPException(status_code=400, detail="Пользователь с таким номером не найден")
    
    code = str(random.randint(1000, 9999))
    try:
        eskiz = EskizService()
        message = f"Kod dlya sbrosa parolya v Yaqin Go: {code}"
        await eskiz.send_sms(clean_phone, message)
    except Exception as e:
        print(f"Eskiz error: {e}")
        raise HTTPException(status_code=500, detail="Не удалось отправить SMS")
    
    ver_code = db.query(VerificationCode).filter(VerificationCode.phone == clean_phone).first()
    if not ver_code:
        ver_code = VerificationCode(phone=clean_phone)
        db.add(ver_code)
    
    ver_code.code = code
    ver_code.expires_at = datetime.now(timezone.utc).replace(tzinfo=None) + timedelta(minutes=5)
    db.commit()
    
    return MessageResponse(message="SMS sent successfully")


@router.post("/reset-password", response_model=MessageResponse)
def reset_password(data: ResetPasswordRequest, db: Session = Depends(get_db)):
    clean_phone = normalize_phone_number(data.phone)
    ver_code = db.query(VerificationCode).filter(VerificationCode.phone == clean_phone).first()
    if not ver_code or ver_code.code != data.code:
        raise HTTPException(status_code=400, detail="Неверный код подтверждения")
    if ver_code.expires_at < datetime.now(timezone.utc).replace(tzinfo=None):
        db.delete(ver_code)
        db.commit()
        raise HTTPException(status_code=400, detail="Код подтверждения истёк")
    db.delete(ver_code)
    user = db.query(User).filter(User.phone == clean_phone).first()
    if not user:
        raise HTTPException(status_code=404, detail="Пользователь не найден")
    if len(data.new_password) < 6:
        raise HTTPException(status_code=400, detail="Пароль должен содержать минимум 6 символов")
    user.password_hash = pwd_context.hash(data.new_password)
    db.commit()
    return MessageResponse(message="Пароль успешно изменён")

'''

# Insert before the login endpoint
content = content.replace(
    '@router.post("/login", response_model=TokenResponse)',
    new_endpoints + '@router.post("/login", response_model=TokenResponse)',
    1
)

with open(auth_path, "w") as f:
    f.write(content)

print("Backend auth.py updated successfully!")
