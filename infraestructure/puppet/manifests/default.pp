Exec {
	path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ]
}

exec { "aptgetupdate":
  user => root,
  group => root,
  command => "apt-get update"
}

# = Class: java
#
# Author: Rafael Avila <rafa.avim@gmail.com>
class java () {

	file {
        "/usr/lib/jvm":
            ensure  => directory,
            owner => root,
    }

    exec {
        'tarJDK':
        	cwd 	=> '/usr/lib/jvm',
            command => 'sudo tar xzvf /files/jdk-7u45-linux-x64.gz',
            user 	=> root,
  			group 	=> root,
    }

    exec {
        'javaAlternative':
            require     => Exec['tarJDK'],
            command     => 'update-alternatives --install "/usr/bin/java" "java" "/usr/lib/jvm/jdk1.7.0_45/bin/java" 1',
            user        => 'root',
            group       => 'root',
    }

    exec {
        'javacAlternative':
            require     => Exec['tarJDK'],
            command     => 'update-alternatives --install "/usr/bin/javac" "javac" "/usr/lib/jvm/jdk1.7.0_45/bin/javac" 1',
            user        => 'root',
            group       => 'root',
    }

    exec {
        'javawsAlternative':
            require     => Exec['tarJDK'],
            command     => 'update-alternatives --install "/usr/bin/javaws" "javaws" "/usr/lib/jvm/jdk1.7.0_45/bin/javaws" 1',
            user        => 'root',
            group       => 'root',
    }

    exec {
        'addJAVASysVars':
            require     => Exec['tarJDK'],
            cwd			=> '/files',
            command     => 'cat javaSysVars.txt >> /home/vagrant/.bashrc',
            user        => 'root',
            group       => 'root',
    }
}

# = Class: neo4j
# http://debian.neo4j.org/
# Author: Rafael Avila <rafa.avim@gmail.com>
class neo4j {
    # puppet code
    require java


    exec {
    'importNeo4jSigningKey':
	        command     => 'wget -O - http://debian.neo4j.org/neotechnology.gpg.key| apt-key add -',
	        user   		=> 'root',
	        group   	=> 'root',
	        timeout 	=> 0,
    }

    exec {
    'createAnAptSourceslistFile':
        require		=> Exec['importNeo4jSigningKey'],
        command     => 'echo "deb http://debian.neo4j.org/repo stable/" > /etc/apt/sources.list.d/neo4j.list',
        user   		=> 'root',
        group   	=> 'root',
        timeout 	=> 0,
    }

    exec {
    'findOutAboutTheFilesInNeo4jRepository':
        require		=> Exec['createAnAptSourceslistFile'],
        command     => 'aptitude update -y',
        user   		=> 'root',
        group   	=> 'root',
        timeout 	=> 0,
    }

    exec {
    'installNeo4jCommunityEdition':
        require		=> Exec['findOutAboutTheFilesInNeo4jRepository'],
        command     => 'aptitude install neo4j -y',
        user   		=> 'root',
        group   	=> 'root',
        timeout 	=> 0,
    }

    exec {
    'allowAnyConntectionToWebAdmin':
        require		=> Exec['installNeo4jCommunityEdition'],
        cwd  		=> '/etc/neo4j',
        command     => 'sudo perl -pe "s/.*/org.neo4j.server.webserver.address=0.0.0.0/ if $. == 16" < neo4j-server.properties',
        user   		=> 'root',
        group   	=> 'root',
        timeout 	=> 0,
    }

    exec {
    'restartServer':
        require		=> Exec['allowAnyConntectionToWebAdmin'],
        cwd  		=> '/var/lib/neo4j/bin',
        command     => 'sudo ./neo4j restart',
        user   		=> 'root',
        group   	=> 'root',
        timeout 	=> 0,
    }
}

# = Class: nodejs
#
# Author: Rafael Avila <rafa.avim@gmail.com>
class nodejs () {
    # puppet code

    require neo4j
    
    $dependencies = ['python', 'g++', 'make', 'checkinstall']

	package {
	    $dependencies:
	        ensure      => installed,
	}

	file {
	    '/usr/lib/nodejs':
	        ensure 		=> directory,
	        owner 		=> 'root',
	}

	file {
	    '/tmp/nodejs':
	    	require 	=> File['/usr/lib/nodejs'],
	        ensure 		=> "directory",
	        owner   	=> 'root',
	}

	exec {
	    'downloadNodeJs':
	    	require		=> File['/tmp/nodejs'],
	    	cwd			=> '/tmp/nodejs',
	        command     => 'wget -N http://nodejs.org/dist/v0.10.22/node-v0.10.22-linux-x64.tar.gz',
	        user   		=> 'root',
	        group   	=> 'root',

	}

	exec {
	    'unpackNode':
	    	require		=> Exec['downloadNodeJs'],
	    	cwd			=> '/tmp/nodejs',
	        command     => 'tar xzvf node-v0.10.22-linux-x64.tar.gz -C /usr/lib/nodejs',
	        user  		=> 'root',
	        group   	=> 'root',
	}

	exec {
	    'addingNodeToPATH':
	    	require		=> Exec['unpackNode'],
	    	cwd	 		=> '/home/vagrant',
	        command     => 'echo "PATH=$PATH:/usr/lib/nodejs/node-v0.10.22-linux-x64/bin/" >> .bashrc',
	        user  		=> 'root',
	        group   	=> 'root',
	}
}

# = Class: installNPMGlobalPackages
#
# Author: Rafael Avila <rafa.avila@gmail.com>
class installNPMGlobalPackages () {
    # puppet code

    require nodejs

    exec {
        'installGlobalPackage':
            cwd        => '/usr/lib/nodejs/node-v0.10.22-linux-x64/bin',
            command     => 'sudo ./npm install forever -g',
            user        => 'root',
            group       => 'root',
    }
}

# = Class: nginx
#
# Author: Rafael Avila <rafa.avila@gmail.com>
class nginx () {
    # puppet code

    require nodejs
    
    # install nginx package
    package { 
        'nginx':
        ensure => installed,
    }

    exec {
        'deleteDefaultNGinXConfig':
            require     => Package['nginx'],
            cwd         => '/etc/nginx',
            command     => 'echo "" nginx.conf',
            user        => 'root',
            group       => 'root',
    }

    exec {
        'setNginXNewConfiguration':
            require     => Exec['deleteDefaultNGinXConfig'],
            cwd         => '/etc/nginx',
            command     => 'cat /files/nginxCongif >> nginx.conf',
            user        => 'root',
            group       => 'root',
    }

    # set nginx as service and starts it up
    # has a ngin package as dependency
    service { 
        'nginx':
        require     => Exec['setNginXNewConfiguration'],
        ensure      => running,
        enable      => true
    }
}

include nodejs

include installNPMGlobalPackages

include nginx