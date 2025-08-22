#!/bin/bash

echo "=== Tworzenie klucza SSH i deployment VPS ==="

# Utworzenie katalogu .ssh i pliku klucza
mkdir -p ~/.ssh
cat > ~/.ssh/klucz1.pem << 'EOF'
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAx7mlBemcf0BolDvkBWbegJklYl67N6zPUG70hco6ZlDp3HZp
S3h4QxVcToOMk0slIRuQnBrvvRgRyryRxCRwaYXvimqYangsfBvHzk9NiFKNkTCa
lgqUCe/+zCk8l2boeUTjQj/u2UuZ4WMkyxjSqabUZyIbQLb9a3qRMVnLHAG+TrQl
21atVJvN2kdTSBeXF3wlJTH43SagnuFtfnBmN47y2p6ZXlLzBvP0KgZP94abAeOk
75HuenbiskNQSKi7HJ3fPInabVh9ve44hpAtW99K2br4j+VZueQ/V4BEtKe/qCyd
bPPPZmTxFECmdmh1UrXuOZirB7pPhseOKaWDZwIDAQABAoIBAQDCGXX6IAW6WZMI
9IduhIGagrslNaFGw0gbCCnVWCqXQu10FxPPh72AnGK/3vKgNvhXi51nSHpSz/CC
ke4rq6ofs02PvHZximbZGnp80u8rm+b/AjhJtvAWFEoQicbb8OPe7wbZXJ64SNO8
igi45F/fBkYIEMphgzUX3d77EiPlC0d2+JHM3P253IFyv3AlHuMocAhNlKL4lue6
1H1bpvMqPtnvUzuNsXMO0vBWxshBBd8VWqMfijF8RJLJ0CF75i19Z5OjkUU1TC8+
/ZBnk1e/wMVTXZtbIbdw35C1Ndzc0efOhKelLiTq+yNbox68V05iYNzO6b4SOjba
jZLcXg9JAoGBAPcUlXYSn+ArUvq714FxXadWoGowXxeGGiM+xW1ee+uYNe/JUor0
TAeq72XnN84qtulCs0s3LynXFuCEO5Ipf4vFEW2JdCYJT4RQiNFHRfsZonVKEx5B
F1YGzYROxSvMyjSCRbKoYSFD/e5UeVDCINVjqMiuSdiSA2uNbSn3qD4tAoGBAM7v
bE9y/jdCE0LF4K9ewDzjctU3eEKwa7hiqStYTUOvNlTyOO61mpn1E6j0edqshd2N
rc9vls2huxmfmlhk+rT8Io6FqnWyoxFxTLoBmNOgHeeSUiDD2oQ60fG0+/ZQ5Lc2
CscNVUZ9ThfT6wBh5uH8aCc+ytIjbZBtdsdezlhjAoGAWGibGkaLwlB+Po1cDUsd
MbVDbPul6urnC1l4lyvJt4EdO5GT4XiMg+ncA2B6jWCnVkuxj+ZND/GQlAF8t031
/3MiS0l1r+6A711Jt2iDV9fSU5mPwbGUwglpHEB7OLLsX2GFwumQ57BGejLrvcPY
r8IbMMN8VOvaIW/Xcb7WCnkCgYAH3ymymAA9n+DVsGtMoIEVj91laPfFKarfV7lx
sak2wuqBLrmlsvjPlHgL/EjKXbe15tbOxkLpTZatcdnQNP8odVLnMwR597KmTjYJ
+VeT7UpV7cX8AxdD4mzsEeNnykn5AjBExCgTR176HxCYciDzRcO8gnH6rmhTjyZu
jReyWwKBgQCrsttE48L2pyg7L93vo2JzLa2Nakdhyk37RKpWaxAW1Y9CsiwynXWX
sTwl7lGmaFhFT+/NNl5AZDMKqrI226UxSkORQ4TzVZtXKwiCPaqUb82fTarh/Psr
+m8g+x0VXhIgws/5haK3xDETFgXtMQ3iWsSzSuIxTxeKjdpsZJVLTA==
-----END RSA PRIVATE KEY-----
EOF

# Ustawienie uprawnień dla klucza
chmod 600 ~/.ssh/klucz1.pem

echo "Klucz SSH utworzony w ~/.ssh/klucz1.pem"

# Test połączenia SSH
echo "Testowanie połączenia SSH..."
ssh -i ~/.ssh/klucz1.pem ubuntu@ec2-13-49-169-63.eu-north-1.compute.amazonaws.com "echo 'Połączenie SSH działa!' && whoami && pwd"

if [ $? -eq 0 ]; then
    echo "✅ Połączenie SSH działa!"
    
    # Uruchomienie deploymentu
    echo "Rozpoczynanie deploymentu..."
    ssh -i ~/.ssh/klucz1.pem ubuntu@ec2-13-49-169-63.eu-north-1.compute.amazonaws.com "bash -s" < simple_deploy.sh
    
else
    echo "❌ Problem z połączeniem SSH"
    echo "Sprawdź:"
    echo "1. Czy klucz jest poprawny"
    echo "2. Czy instancja jest uruchomiona"
    echo "3. Czy security group pozwala na SSH (port 22)"
fi
