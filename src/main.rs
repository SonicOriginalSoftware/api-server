use actix_web::web;
use std::path::Path;

use pwa_server::{
    api::route as api_route,
    app::{root, route as app_route, state::App as AppState},
    auth::route as auth_route,
};

// TODO The below main function body needs the port to be configurable
// And once that is done, it can be abstracted into a shared module
// Each component will pretty much only use these scopes, and so the
// abstracted-out function should accept callbacks to handlers for
// these scopes

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    // FIXME Make the scheme, host, port, and app path configurable based on env variables
    // and/or arguments in the executable

    // TODO Server should be running on HTTP/2 over SSL/TLS

    const SCHEME: &str = "http";
    const HOST: &str = "localhost";
    const PORT: u32 = 8080;

    let pwa_path: String = match std::env::var("PWA_PATH") {
        Ok(p) => p,
        Err(e) => {
            eprintln!("{}", e);
            String::from("public")
        }
    };

    let app_state = AppState {
        name: env!("CARGO_PKG_NAME"),
        version: env!("CARGO_PKG_VERSION"),
        path: Path::new(&pwa_path).to_path_buf(),
    };

    println!("{}", app_state);

    println!("Starting server on {}://{}:{}...", SCHEME, HOST, PORT);

    use actix_web::{middleware, App, HttpServer};

    // FIXME Logging not working

    let app_data = web::Data::new(app_state);

    HttpServer::new(move || {
        App::new()
            .wrap(middleware::Logger::default())
            .wrap(middleware::DefaultHeaders::default())
            .wrap(middleware::NormalizePath::new(
                middleware::normalize::TrailingSlash::MergeOnly,
            ))
            .app_data(app_data.clone())
            .route("/", web::get().to(root))
            .route(pwa_path.as_str(), web::get().to(app_route))
            .route("/{filename:.*}", web::get().to(app_route))
            .service(web::resource("/api").to(api_route))
            .service(web::resource("/auth").to(auth_route))
    })
    .bind(format!("{}:{}", HOST, PORT))?
    .run()
    .await
}
