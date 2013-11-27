#!/bin/bash

#mysql -hdb -uroot -p2sh\!db -e "select * from folderplus.member";

for user in `cat userlist`
do

mysql -hdb -uroot -e "insert into folderplus.member(id, passwd, passwd_q, passwd_a, name, reg_num1, reg_num2, email, mdate, coin, charge_num, charge_size, storage) values('$user', '@mb\!an', 'q', 'a', '$user','123456' , '1234567', '$user@embian.com', now(), 100000, 0, 0, '0');" 

done
