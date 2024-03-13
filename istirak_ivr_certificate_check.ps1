# Sertifika Kontrol script'i

# sunucu hostname'i
$hostname = hostname
# keytool.exe'nin bulunduðu path
$keytool_path = "C:\Cisco\CVP\jre\bin"
# cacert sertifikalarýn bulunduðu dosya
$cacerts_path = "C:\Cisco\CVP\jre\lib\security\cacerts"
# keytool þifresi
$keytool_pass = "PASSWORD"
# mail attachment dosyasýnýn path'i, opsiyoneldir. kullanýlmayacaksa koddan da silinebilir.
$mail_attachment = "D:\Admin_Job\certificate_info.txt"
# sertifika adlarýnýn export edildiði dosya adý
$cert_list_path = "D:\Admin_Job\certificate_names_list.txt"

# SMTP Server parametreleri
$from_mail = "Istirak IVR-Sertifika-Bilgilendirme <$hostname@company.com.tr>"
$to_mail = "Teamname1 <Teamname1@company.com.tr>", "Teamname2 <Teamname2@company.com.tr>"
# $to_mail = "Username <Username@company.com.tr>"
$mail_subject = "Uygulama $hostname Server Sertifika Kontrol"
$smtp_server = "smtp.company.com.tr"

cd $keytool_path

# Built-in olmayan serfikalarý bulma
$cert_list = .\keytool.exe -list -keystore $cacerts_path -storepass $keytool_pass -rfc | Select-String -Pattern "jdk" -NotMatch | Select-String "Alias name:"
$cert_list = $cert_list -replace '^.{12}', ''
Write-Output $cert_list > $cert_list_path
[string[]]$cert_list = Get-Content -Path $cert_list_path

$cert_output_list = @()
$certs_summary = @()
$cert_detail_output_list = @()
$certs_details = @()

# Sertifika özet bilgilerini çekme
for ($i = 0; $i -le $cert_list.Length - 1; $i++) { 
    $cert_output_list +=  .\keytool.exe -list -keystore $cacerts_path -storepass $keytool_pass | Select-String -Pattern $cert_list[$i] -Context 0,1
    $cert_output_list += "<br>"
} 

for ($i = 0; $i -le $cert_output_list.Length - 1; $i++) { 
    $certs_summary += $cert_output_list[$i]
} 

# Sertifika detay bilgilerini çekme
for ($i = 0; $i -le $cert_list.Length - 1; $i++) { 
    $cert_detail_output_list +=  .\keytool.exe -list -v -alias $cert_list[$i] -keystore $cacerts_path -storepass $keytool_pass
    $cert_detail_output_list += "<br><br>"
} 

for ($i = 0; $i -le $cert_detail_output_list.Length - 1; $i++) { 
    $certs_details += $cert_detail_output_list[$i]
} 

# Mail body içeriðini hazýrlama
$mail_body_content = "<b>Sertifika bilgileri ozet:</b><br>" + $certs_summary + "<br>" + "<b>Sertifika detaylari: </b><br>" + $certs_details

# Mail gönderimi
Send-MailMessage -From $from_mail -To $to_mail -Subject $mail_subject -Attachments $mail_attachment -Body "Merhaba,<br><br>$hostname sunucusunda, Java keytool'daki sertifikalar kontrol edilmistir. <br><br> $mail_body_content <br><b><u><i>Not: Java sertifikalari hakkinda bilgi icin ekteki dosyadaki yonlendirmeleri takip edebilirsiniz. Sertifikalar hakkinda bilgi icin 'Company Team' ekibi ile iletisime gecebilirsiniz.</i></u></b><br><br>Iyi calismalar<br>Teamname1" -BodyAsHtml -Priority High -SmtpServer $smtp_server

Write-Output "Sertifika detaylari basariyla gonderildi. `n$mail_body_content"
