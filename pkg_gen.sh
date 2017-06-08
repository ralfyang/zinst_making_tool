#!/bin/bash
# zinst_making_tool version 1.2.9

BaseRoot=`cat /usr/bin/zinst |grep "^ZinstBaseRoot=" | awk -F'=' '{print $2}' | sed -s 's/"//g'`
export TIME_STYLE="+%Y-%m-%d %H:%M:%S"

Option=$1
Option2=$2

OutputLog=$BaseRoot/var/null
#OutputLog=/dev/null

mailing=code-post.com
OS_type="OS"

	if [[ $Option = "make" ]]
	then
		Account=`whoami`
		Tar="package_creator.tgz"
		PWD=`pwd`
		Dir=`echo $PWD |awk -F '/' '{print $NF}'`
		## Package name define
		echo " "
		echo " === Please insert an information for the index file create ==="
		echo " "
		echo " * [ Package name: Default=$Dir ] ="
		echo " ! Notice: You only can use a package name with Alphabet, Number, _(underscore) combination"
		read zicf
			if [[ $zicf = "" ]]; then	
				zicf=$Dir
			fi

		## Index file name define
		zicfN="$zicf.zicf"

		if [[ $OS_type = "OS" ]];then
			## OS type
			echo " OS type: rhel7 or rhel, ubuntu, osx, freebsd"
			echo " * [ OS Type] ="
			read OS_type
				if [[ $OS_type = "" ]]; then	
					Desc="Please insert an OS name for package environment"
				fi
		fi

		## Description
		echo " "
		echo " * [ Description] ="
		read Desc
			if [[ $Desc = "" ]]; then	
				Desc="Please insert a description for this package"
			fi
  
		## Version
		echo " "
		echo " * [ Version: Default=0.0.1 ] = "
		read Ver
			if [[ $Ver = "" ]]; then	
				Ver="0.0.1"
			fi

		## Deafult Owner
		echo " "
		echo " * [ Default Owner: Default=root ] = "
		read Owner
			if [[ $Owner = "" ]]; then	
				Owner="root"
			fi

		## Deafult Owner
		echo " "
		echo " * [ Default Group: Default=wheel ] = "
		read Group
			if [[ $Group = "" ]]; then	
				Group="wheel"
			fi
  
		## Deafult Permission
		echo " "
		echo " * [ Defaut Permission: Default=664 ] = "
		read Permission
			if [[ $Permission = "" ]]; then	
				Permission="664"
			fi

		## Uninstall command
		echo " "
		echo " Do you need a some command when this pacakge removed ?"
		echo " * [ y/n : Default=n ] = "
		read Unin_com
			if [[ $Unin_com = "" ]] || [[ $Unin_com = "n" ]]; then	
				Uninstall_comm="#ZINST activate-uninstall"
			else 
				Uninstall_comm="ZINST activate-uninstall"
				touch ./uninstall.sh
				sudo chmod 775 ./uninstall.sh
			fi
		## Require package
		Barr="======================================================="
		echo " "
		echo " Do you have a required pacakge ?"
		echo " * [ y/n : Default= n ]"
		read Requires_pkg
			if [[ $Requires_pkg = "" ]] || [[ $Unin_com = "n" ]]; then
				Require_package="#ZINST requires pkg perl-log4j"
			else
				ElsePkg="y"
				OutGoing="0"
				while [ $ElsePkg = "y" ]; do
					echo ""
					echo " * Please insert a package name ="
					read ReqPkg
					echo $Barr
						if [[ $ReqPkg != "" ]]; then
							Count=0
							ResultArry=(`zinst find $ReqPkg | awk -F '-' '{print $1}' | sort -u`)
								while [ $Count -lt ${#ResultArry[@]} ]; do
								let NumM=$Count+1
									printf " %-50s %-10s\n" "${ResultArry[$Count]}" "[${NumM}]"
								let Count=$Count+1
								done
								if [[ ${ResultArry[@]} != "" ]];then
									echo $Barr
									echo " * Please insert a number what you need [ 1 - ${#ResultArry[@]} ] ?"
									read PkgNum
										if [[ $PkgNum != "" ]]; then
											let PkgNum=$PkgNum-1
											echo " [ ${ResultArry[$PkgNum]} ] package has been selected. "
											ReqPkgArry[$OutGoing]=${ResultArry[$PkgNum]}
										else
											echo " Nothing selected. "
										fi
								else
									echo "  === Package name is not correct. ==="
								fi
						fi
					echo ""
					echo " Do you need more package require ? [y/n]"
					read ElsePkg
						if [[ $ElsePkg = "n" ]] || [[ $ElsePkg = "N" ]] || [[ $ElsePkg = "" ]] ;then
							break ;
						fi
					let OutGoing=OutGoing+1
				done

					if [[ ${ReqPkgArry[@]} != "" ]] ;then
						Require_package="ZINST requires pkg ${ReqPkgArry[@]}"
					else
						Require_package="#ZINST requires pkg perl-log4j"
					fi

			fi

		## Make sure the work directory
		cd $PWD
		tar cvzf ./$Tar ./*
		tar tvf $Tar > ./listup
    
		echo "" > ./perm.txt
		## ==================  Create zicf base file =================
		echo "" > ./$zicfN
		echo "### Package infomation" >> ./$zicfN
		echo "## OS type: rhel7 or rhel, ubuntu, osx, freebsd" >> ./$zicfN
		echo "OS = $OS_type" >> ./$zicfN
		echo "PACKAGENAME = $zicf" >> ./$zicfN
		echo "VERSION = $Ver" >> ./$zicfN
		echo "AUTHORIZED = $Account@$mailing" >> ./$zicfN
		echo "DESCRIPTION = '$Desc'" >> ./$zicfN
		echo "CUSTODIAN = codepost-infra" >> ./$zicfN
		echo "" >> ./$zicfN
		echo "### Global setting of the files" >> ./$zicfN
		echo "OWNER = $Owner" >> ./$zicfN
		echo "GROUP = $Group" >> ./$zicfN
		echo "PERM = $Permission" >> ./$zicfN
		echo "">> ./$zicfN
		echo "">> ./$zicfN
		echo "### Regular Syntax" >> ./$zicfN
		echo "### Based root Directory = $BaseRoot/" >> ./$zicfN
		echo "## --------------------------------------------------------------------------------------------------------------------" >> ./$zicfN
		echo "## Option type | File Permission | File Owner | File Group | Destination Dir | Source Dir | Conf option(CONF type only)" >> ./$zicfN
		echo "## --------------------------------------------------------------------------------------------------------------------" >> ./$zicfN
		echo "##" >> ./$zicfN
		echo "## Option type = FILE - Sorce file, CONF - Configuration file, SYMB - Symbolic link, CRON - Crontab" >> ./$zicfN
		echo "## File permission =  ex)664 or \"-\" ( \"-\" is default, it will be accept by global setting if you used it)" >> ./$zicfN
		echo "## File Owner =  ex)krystal or root or \"-\" ( \"-\" is default, it will be accept by global setting if you used it)" >> ./$zicfN
		echo "## File group =  ex)krystal or wheel or \"-\" ( \"-\" is default, it will be accept by global setting if you used it)" >> ./$zicfN
		echo "## Destinatin Dir = Target directory for the file copy or symbolic link" >> ./$zicfN
		echo "## Source Dir = Source directory for the file copy or symbolic link" >> ./$zicfN
		echo "## Conf option - ex) expand-overwite or expand-nomerge, Optional: file overwrite or not(CONF only), default = expand-overwrite" >> ./$zicfN
		echo "">> ./$zicfN
		echo "#CONF 664 - -			tmp/conf/httpd_gsshp.conf		./conf/httpd_gsshop.conf" >> ./$zicfN
		echo "#FILE - - -				tmp/logrotation.sh			./logrotation.sh" >> ./$zicfN
		echo "#FILE - nobody nobody	tmp/www/index.html			./html/index.html" >> ./$zicfN
		echo "#SYMB x x x				tmp/www/top.html			tmp/www/index.html" >> ./$zicfN
		echo "#CRON x - x				* * * * *					tmp/logrotation.sh" >> ./$zicfN
		echo "">> ./$zicfN
		echo "">> ./$zicfN.footer
		echo "### Zinst detail command" >> ./$zicfN.footer
		echo "### requires pkg = You can add an option to this line about of the dependency package for this work(install or upgrade)." >> ./$zicfN.footer
		echo "### ex) ZINST requires pkg [Packagename] [Lowest version] [latest version]" >> ./$zicfN.footer
		echo "">> ./$zicfN.footer
		echo "### set = You can control the configuration in the CONF file by this options" >> ./$zicfN.footer
		echo "### ex) ZINST set [Variables name] [Value]" >> ./$zicfN.footer
		echo "#ZINST set MaxClient 64" >> ./$zicfN.footer
		echo "">> ./$zicfN.footer
		echo "### post-activate = You can contral the daemon after the package install as below" >> ./$zicfN.footer
		echo "### ex) ZINST post-activate [Target executable file and directory] [Command: stop, start, restart]" >> ./$zicfN.footer
		echo "#" >> ./$zicfN.footer
		echo "">> ./$zicfN.footer
		echo "#ZINST post-activate $BaseRoot/tomcat/bin/tomcat restart" >> ./$zicfN.footer
		echo "$Require_package " >> ./$zicfN.footer
		echo "">> ./$zicfN.footer
		echo "">> ./$zicfN.footer
		echo "### If you need a some command excute while the package remove, you can activate as below option with modify the ./uninstall.sh file"  >> ./$zicfN.footer
		echo "$Uninstall_comm" >> ./$zicfN.footer
		echo "">> ./$zicfN.footer
		echo "">> ./$zicfN.footer
		echo "### Extra command" >> ./$zicfN.footer
		echo "## COMM = simple command after the package installed. basedir is the package dir " >> ./$zicfN.footer
		echo "## ex) " >> ./$zicfN.footer
		echo "## COMM $BaseRoot/zinst/foo.bar/install.sh" >> ./$zicfN.footer
		echo "#COMM service network restart" >> ./$zicfN.footer
		
    
		## ==================  End zicf Base file ===================
		cat ./listup | awk '{print "stat -c \"%A (%a) %8s %.19y %n\"  " $6,"\| awk \#%{print $2,$6}\#% \>> ./perm.txt "}' > ./Package_gen.sh 2> $OutputLog 
		sed -i '/\/ | /d' ./Package_gen.sh 
		sed -i "s/#%/'/g" ./Package_gen.sh
		chmod 775 ./Package_gen.sh 

		## Need a time for genarating
		#===============================================================================
		./Package_gen.sh 
		#===============================================================================
		cat ./perm.txt | sed 's/(//g' | sed 's/)//g' | awk '{print "FILE",$1,"- -", $2,"\t\t",$2}' |sed 's/- .\//- /g' > Package.zicf
		sed -i '/FILE  - - /d' ./Package.zicf
    
    
			if [[ $Option2 = "-default" ]]
			then
				sed -i 's/ - - / - - z\/temp\//g' ./Package.zicf
			fi
    
		cat Package.zicf >> ./$zicfN
    
		sed -i 's/FILE 777 - -/SYMB x x x/g' ./$zicfN
		#echo " ==== Need to change below list for the Symbolic link ==== "
		grep "^SYMB x" $zicfN | awk '{print $1,$2,$3,$4,$6,"\t",$5}' > ./symb.txt


		RowCount=`cat symb.txt |awk '{print NR}' | tail -1`
		Count=1
		touch ParsedSymb.txt
			while [[ $Count -le $RowCount ]]
			do
				RowSymb=`cat symb.txt |awk 'NR=='$Count' {print }' `
				ChangedIndex=`echo $RowSymb | awk '{print $1,$2,$3,$4,$5}' | sed -e 's/\.\///g'`
				TargetSymb=`echo "$RowSymb" | awk '{print $5}'`
				OriginFile=`echo "$TargetSymb" | awk -F '/' '{print $NF}'`
				OriginDir=`echo "$TargetSymb" | sed -e "s/$OriginFile//g"`
				FixedDir=`echo "$OriginDir" | sed -e "s/^\.\///g"`
				ResultSymb=`ls -l $OriginDir | grep " $OriginFile " |awk '{print $10}'`
			
				DirCheck=`echo $ResultSymb | grep "/"`
					if [[ $DirCheck = "" ]]
					then
						ResultSymb=$FixedDir$ResultSymb
					fi
			
				echo -e "$ChangedIndex \t $ResultSymb" >> ParsedSymb.txt
			
				let Count=$Count+1
			done

		sed -i '/^SYMB x/d'  ./$zicfN
		cat ./ParsedSymb.txt >> ./$zicfN
		cat $zicfN.footer >> ./$zicfN
			if [[ $Unin_com = "" ]] || [[ $Unin_com = "n" ]]; then	
				:
			else 
				touch ./uninstall.sh
				sudo chmod 775 ./uninstall.sh
			fi
 
		## Clear Temporary files
	    sudo chmod 664 ./$zicfN
	    sudo chgrp wheel ./$zicfN
		rm -f ./perm.txt ./$Tar ./Package_gen.sh ./listup ./Package.zicf ./$zicfN.footer  ./symb.txt ParsedSymb.txt

	else
		echo ""
		echo "===================================================================================="
		echo "= make: Make a new zicf file as a filelist in current directory                    ="
		echo "= make -default: Set default directory add as \"z/temp/~\" before the result files   ="
		echo "===================================================================================="
		exit 0;
	fi
