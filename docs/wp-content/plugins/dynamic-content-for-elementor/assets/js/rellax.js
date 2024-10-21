(function ($) {
    var WidgetElements_RellaxHandlerFront = function ($scope, $) {
        var elementSettings = dceGetElementSettings($scope);
        var rellax = null;

        $(window).on('resize', function () {
            if (rellax) {
                rellax.destroy();
                if (rellax){
					initRellax();
				}
			}
        });
		
        var initRellax = function () {
            if (! elementSettings.enabled_rellax) {
				return;
			}

			let currentDevice = elementorFrontend.getCurrentDeviceMode();
			let setting_speed = currentDevice === 'desktop' ? 'speed_rellax' : 'speed_rellax_' + currentDevice;
			let value_speed = elementSettings[setting_speed] ? elementSettings[setting_speed].size : 0;
			let rellaxId = '#rellax-' + $scope.data('id');

			if( $(rellaxId).length ) {
				rellax = new Rellax(rellaxId, { speed: value_speed, } );
			}
        };

        initRellax();
    };

    $(window).on('elementor/frontend/init', function () {
        elementorFrontend.hooks.addAction('frontend/element_ready/global', WidgetElements_RellaxHandlerFront);
    });
})(jQuery);
