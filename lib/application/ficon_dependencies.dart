import '../adapters/http/ficon_monitoring_repository.dart';
import '../usecase/create_site_service.dart';
import '../usecase/get_devices_service.dart';
import '../usecase/get_events_service.dart';
import '../usecase/get_incidents_service.dart';
import '../usecase/get_monitoring_overview_service.dart';
import '../usecase/get_notification_templates_service.dart';
import '../usecase/get_sites_service.dart';
import '../usecase/update_device_details_service.dart';

class FiconDependencies {
  FiconDependencies(FiconMonitoringRepository repository)
    : getOverview = GetMonitoringOverviewService(repository),
      getDevices = GetDevicesService(repository),
      getIncidents = GetIncidentsService(repository),
      getEvents = GetEventsService(repository),
      getNotificationTemplates = GetNotificationTemplatesService(repository),
      getSites = GetSitesService(repository),
      updateDeviceDetails = UpdateDeviceDetailsService(repository),
      createSite = CreateSiteService(repository);

  final GetMonitoringOverviewService getOverview;
  final GetDevicesService getDevices;
  final GetIncidentsService getIncidents;
  final GetEventsService getEvents;
  final GetNotificationTemplatesService getNotificationTemplates;
  final GetSitesService getSites;
  final UpdateDeviceDetailsService updateDeviceDetails;
  final CreateSiteService createSite;
}
