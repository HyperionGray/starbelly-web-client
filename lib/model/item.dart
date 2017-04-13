import 'dart:convert';
import 'dart:typed_data';

import 'package:convert/convert.dart' as convert;

import 'package:starbelly/protobuf/protobuf.dart' as pb;

var RUN_STATE_LABELS = {
    pb.JobRunState.CANCELLED: 'Cancelled',
    pb.JobRunState.COMPLETED: 'Completed',
    pb.JobRunState.PAUSED: 'Paused',
    pb.JobRunState.PENDING: 'Pending',
    pb.JobRunState.RUNNING: 'Running',
};

/// An item fetched by a crawl job.
class CrawlItem {
    Uint8List body;
    String bodyStr;
    DateTime completedAt;
    String contentType;
    num cost;
    num duration;
    String exception;
    List<HttpHeader> headers;
    bool isBodyCompressed;
    bool isSuccess;
    String jobId;
    DateTime startedAt;
    int statusCode;
    String url;

    /// Instantiate CrawlItem from a protobuf.
    CrawlItem.fromPb2(pb.CrawlItem pbItem) {
        // These fields should always be present.
        this.completedAt = DateTime.parse(pbItem.completedAt).toLocal();
        this.contentType = pbItem.contentType;
        this.cost = pbItem.cost;
        this.duration = pbItem.duration;
        this.isBodyCompressed = pbItem.isBodyCompressed;
        this.isSuccess = pbItem.isSuccess;
        this.jobId = convert.hex.encode(pbItem.jobId);
        this.startedAt = DateTime.parse(pbItem.startedAt).toLocal();
        this.url = pbItem.url;

        // These fields are only present for success/error items.
        if (pbItem.hasStatusCode()) {
            this.statusCode = pbItem.statusCode;
        }
        this.headers = new List<HttpHeader>.generate(
            pbItem.headers.length,
            (index) {
                var header = pbItem.headers[index];
                return new HttpHeader(header.key, header.value);
            }
        );
        if (pbItem.hasBody()) {
            this.body = pbItem.body;
            // TODO handle other character sets
            try {
                this.bodyStr = UTF8.decode(this.body);
            } catch (exc, trace) {
                this.bodyStr = 'Error: unable to decode response body.';
            }
        }

        // This field is only present for exception items.
        if (pbItem.hasException()) {
            this.exception = pbItem.exception;
        }
    }
}

/// Represents a single HTTP header line.
class HttpHeader {
    String name, value;
    HttpHeader(this.name, this.value);
}
