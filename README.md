# IssabelLetsEncrypt
get and set Lets Encrypt Certificate on Issabel PBX

معرفی ماژول
ماژول LetsEncrypt برای ایزابل 5، یک ابزار کدباز و رایگان است که توسط تیم ویپ ایران طراحی شده تا به راحتی امکان دریافت و نصب گواهی SSL معتبر از LetsEncrypt را بر روی سیستم تلفنی Issabel فراهم کند.
با این ماژول، گواهی رایگان SSL برای دامنه‌ای که به سرور Issabel متصل شده، به صورت خودکار دریافت و در وب‌سرور Apache تنظیم می‌شود.

🌐 چرا گواهی SSL در ایزابل اهمیت دارد؟
افزایش امنیت پنل مدیریتی ایزابل: اطلاعات ورود مدیر، تماس‌ها و لاگ‌ها رمزگذاری می‌شود.

دسترسی امن از راه دور: برای اتصال به پنل وب از طریق HTTPS بدون هشدار مرورگر.

پشتیبانی از برنامه‌ها و APIهای خارجی: بسیاری از برنامه‌های مدیریت تماس و REST APIها نیاز به اتصال امن دارند.


# Installation
just run on your Issabel Linux CLI:
```
curl -s -L https://github.com/voipiran/IssabelLetsEncrypt/master/getLetsIssabel.sh | bash
```

## Give a Star! ⭐ یک ستاره با ما بدهید
If you like this project or plan to use it in the future, please give it a star. Thanks 🙏
