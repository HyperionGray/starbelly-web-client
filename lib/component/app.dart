import 'dart:html';

import 'package:angular2/core.dart';
import 'package:angular2/router.dart';
import 'package:logging/logging.dart';
import 'package:ng2_fontawesome/ng2_fontawesome.dart';
import 'package:ng2_modular_admin/ng2_modular_admin.dart';

import 'package:starbelly/component/dashboard.dart';
import 'package:starbelly/component/rate_limit.dart';
import 'package:starbelly/component/results/router.dart';
import 'package:starbelly/component/start.dart';
import 'package:starbelly/service/document.dart';
import 'package:starbelly/service/job_status.dart';
import 'package:starbelly/service/server.dart';

@Component(
    selector: 'app',
    templateUrl: 'app.html',
    styles: const ['''
        ma-side-nav-header {
            font-size: 1.5em;
            font-weight: 600;
        }

        ma-side-nav-header img {
            margin-left: -0.2em;
        }

        .breadcrumbs a {
            text-decoration: none;
        }

        .breadcrumbs fa.separator {
            margin-left: 0.5em;
            margin-right: 0.5em;
        }
    '''],
    directives: const [MA_DIRECTIVES, ROUTER_DIRECTIVES, FaIcon],
    providers: const [MA_PROVIDERS, ROUTER_PROVIDERS, JobStatusService,
        DocumentService, ServerService]
)
@RouteConfig(const [
    const Route(
        path: '/dashboard',
        name: 'Dashboard',
        component: DashboardView,
        useAsDefault: true),
    const Route(
        path: '/rate-limit',
        name: 'RateLimits',
        component: RateLimitView),
    const Route(
        path: '/results/...',
        name: 'Results',
        component: ResultsRouter),
    const Route(
        path: '/start',
        name: 'StartCrawl',
        component: StartCrawlView),
])
class AppComponent {
    /// Service for getting status of jobs.
    DocumentService document;

    /// Service for getting status of jobs.
    JobStatusService jobStatus;

    /// Server service.
    ServerService server;

    /// Service for creating toast notifications.
    ToastService toast;

    /// Constructor.
    AppComponent(this.document, this.jobStatus, this.server, this.toast) {
        if (window.localStorage['starbelly-debug'] == 'true') {
            Logger.root.level = Level.ALL;
        } else {
            Logger.root.level = Level.SEVERE;
        }

        Logger.root.onRecord.listen((LogRecord r) {
            var msg = '[${r.level.name}] ${r.loggerName}: ${r.message}';
            if (r.object != null) {
                msg += ' (Object: ${r.object.toString()})';
            }
            print(msg);
        });

        this.server.stayConnected();
    }
}
