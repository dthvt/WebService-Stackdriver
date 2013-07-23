use 5.008000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'WebService::Stackdriver',
    VERSION_FROM      => 'lib/WebService/Stackdriver.pm', # finds $VERSION
    PREREQ_PM         => {
    	Date::Time => 1.00,
		JSON => 2.00,
		LWP::UserAgent => 6.00,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/WebService/Stackdriver.pm', # retrieve abstract from module
       AUTHOR         => 'Daniel Hagan <daniel@kickidle.com>') : ()),
);
