(function($){
  var parser = new UAParser();

  $(function(){
    ret = parser.getResult();

    var os = (function(n){
      var linuxes = [
        'Arch', 'CentOS', 'Fedora', 'Debian', 'Gentoo', 'Joli', 'Linpus',
        'Linux', 'Mageia', 'Mandriva', 'MeeGo', 'Mint', 'PCLinuxOS', 'RedHat',
        'Slackware', 'SUSE', 'Ubuntu', 'VectorLinux', 'Zenwalk'
      ];

      if (n == 'Windows')             return 'windows';
      if (n == 'Mac OS')              return 'macosx';
      if ($.inArray(n, linuxes) >= 0) return 'linux';

      return null;
    })(ret.os.name);

    var arch = (function(a, os){
      if (a == 'ia64' || a == 'amd64' || os == 'macosx') return 'x64';
      if (a == 'ia32') return 'x86'

      return null;
    })(ret.cpu.architecture, os);

    if (os && arch) {
      $('.download-button').each(function(){
        var btn  = $(this).find('a.btn:first');
        var link = $(this).find('.dropdown-menu').find('a.' + os + '.' + arch);

        if (link.length > 0) {
          btn.attr('target', '').attr('href', link.attr('href'));
          link.addClass('recommend');
        }
      });
    }
  });
})(jQuery);
