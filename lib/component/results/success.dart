import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:convert/convert.dart' as convert;
import 'package:ng_fontawesome/ng_fontawesome.dart';
import 'package:ng_modular_admin/ng_modular_admin.dart';

import 'package:starbelly/component/external_link.dart';
import 'package:starbelly/model/item.dart';
import 'package:starbelly/model/job.dart';
import 'package:starbelly/protobuf/protobuf.dart' as pb;
import 'package:starbelly/service/job_status.dart';
import 'package:starbelly/service/document.dart';
import 'package:starbelly/service/server.dart';

/// View successful crawl items.
@Component(
    selector: 'results-success',
    styles: const ['''
        table {
            table-layout: fixed;
        }
        td pre {
            overflow-x: auto;
            margin-bottom: 0;
        }
        td.expanded {
            /* This makes no sense, but it fixes an x-overflow bug. */
            max-width: 0
        }
        td:nth-child(1) {
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }
        th:nth-child(2) {
            width: 5em;
        }
        th:nth-child(3) {
            width: 4em;
        }
        th:nth-child(4) {
            width: 6em;
        }
    '''],
    templateUrl: 'success.html',
    directives: const [CORE_DIRECTIVES, FaIcon, MA_DIRECTIVES,
        RouterLink, ExternalLinkComponent],
    pipes: const [COMMON_PIPES]
)
class ResultSuccessView implements AfterViewInit {
    int currentPage = 1;
    int endRow = 0;
    List<CrawlItem> items;
    String jobId;
    String jobName;
    int rowsPerPage = 10;
    int showBody;
    int startRow = 0;
    int totalRows = 0;

    DocumentService _document;
    JobStatusService _jobStatus;
    RouteParams _routeParams;
    ServerService _server;
    StreamSubscription<Job> _subscription;

    /// Constructor
    ResultSuccessView(this._document, this._jobStatus, this._routeParams,
        this._server) {
        this.jobId = this._routeParams.get('id');
        this._document.title = 'Successes';
        this._document.breadcrumbs = [
            new Breadcrumb(name: 'Results', icon: 'sitemap',
                link: ['/Results', 'List']),
            new Breadcrumb(name: 'Crawl',
                link: ['/Results', 'Detail', {'id': this.jobId}]),
            new Breadcrumb(name: 'Successes')
        ];

        this._jobStatus.getName(this.jobId).then((jobName) {
            this.jobName = jobName;
            this._document.breadcrumbs[1].name = jobName;
        });

        this._subscription = this._jobStatus.events.listen((Job update) {
            if (this.jobId == update.jobId &&
                (update.itemCount ?? 0) > this.totalRows) {
                this.totalRows = update.itemCount;
                if (items != null && items.length != this.rowsPerPage) {
                    this.getPage();
                }
            }
        });
    }

    /// Fetch current page.
    getPage() async {
        this.showBody = null;
        var request = new pb.Request();
        request.getJobItems = new pb.RequestGetJobItems()
            ..jobId = convert.hex.decode(this.jobId)
            ..compressionOk = false
            ..includeSuccess = true;
        request.getJobItems.page = new pb.Page()
            ..limit = this.rowsPerPage
            ..offset = (this.currentPage - 1) * this.rowsPerPage;
        var message = await this._server.sendRequest(request);
        var pbItems = message.response.listItems.items;
        this.totalRows = message.response.listItems.total;
        this.items = new List<CrawlItem>.generate(
            pbItems.length,
            (i) => new CrawlItem.fromPb2(pbItems[i])
        );
        this.startRow = (this.currentPage - 1) * this.rowsPerPage + 1;
        this.endRow = this.startRow + this.items.length - 1;
    }

    /// Called when Angular initializes the view.
    ngAfterViewInit() async {
        this.getPage();
    }

    /// Called when Angular destroys the view.
    void ngOnDestroy() {
        this._subscription.cancel();
    }

    /// Called by the pager to select a new page.
    void selectPage(Page page) {
        this.currentPage = page.pageNumber;
        this.getPage();
    }
}
