--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: hstore; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS hstore WITH SCHEMA public;


--
-- Name: EXTENSION hstore; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION hstore IS 'data type for storing sets of (key, value) pairs';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: admins; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE admins (
    id integer NOT NULL,
    email character varying(255) DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying(128) DEFAULT ''::character varying NOT NULL,
    password_salt character varying(255) DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying(255),
    remember_token character varying(255),
    remember_created_at timestamp without time zone,
    sign_in_count integer DEFAULT 0,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip character varying(255),
    last_sign_in_ip character varying(255),
    failed_attempts integer DEFAULT 0,
    locked_at timestamp without time zone,
    invitation_token character varying(60),
    invitation_sent_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    reset_password_sent_at timestamp without time zone,
    invitation_accepted_at timestamp without time zone,
    invitation_limit integer,
    invited_by_id integer,
    invited_by_type character varying(255),
    roles text,
    unconfirmed_email character varying(255),
    authentication_token character varying(255)
);


--
-- Name: admins_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE admins_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admins_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE admins_id_seq OWNED BY admins.id;


--
-- Name: client_applications; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE client_applications (
    id integer NOT NULL,
    user_id integer,
    name character varying(255),
    url character varying(255),
    support_url character varying(255),
    callback_url character varying(255),
    key character varying(40),
    secret character varying(40),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: client_applications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE client_applications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: client_applications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE client_applications_id_seq OWNED BY client_applications.id;


--
-- Name: deal_activations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE deal_activations (
    id integer NOT NULL,
    deal_id integer,
    user_id integer,
    activated_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: deal_activations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE deal_activations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: deal_activations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE deal_activations_id_seq OWNED BY deal_activations.id;


--
-- Name: deals; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE deals (
    id integer NOT NULL,
    token character varying(255),
    name character varying(255),
    description text,
    kind character varying(255),
    value double precision,
    availability_scope character varying(255),
    started_at timestamp without time zone,
    ended_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: deals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE deals_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: deals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE deals_id_seq OWNED BY deals.id;


--
-- Name: delayed_jobs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE delayed_jobs (
    id integer NOT NULL,
    priority integer DEFAULT 0,
    attempts integer DEFAULT 0,
    handler text,
    last_error text,
    run_at timestamp without time zone,
    locked_at timestamp without time zone,
    failed_at timestamp without time zone,
    locked_by character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: delayed_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE delayed_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: delayed_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE delayed_jobs_id_seq OWNED BY delayed_jobs.id;


--
-- Name: enthusiast_sites; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE enthusiast_sites (
    id integer NOT NULL,
    enthusiast_id integer,
    hostname character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: enthusiast_sites_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE enthusiast_sites_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: enthusiast_sites_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE enthusiast_sites_id_seq OWNED BY enthusiast_sites.id;


--
-- Name: enthusiasts; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE enthusiasts (
    id integer NOT NULL,
    email character varying(255),
    free_text text,
    interested_in_beta boolean,
    remote_ip character varying(255),
    confirmation_token character varying(255),
    confirmed_at timestamp without time zone,
    confirmation_sent_at timestamp without time zone,
    trashed_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    invited_at timestamp without time zone,
    starred boolean,
    confirmation_resent_at timestamp without time zone
);


--
-- Name: enthusiasts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE enthusiasts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: enthusiasts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE enthusiasts_id_seq OWNED BY enthusiasts.id;


--
-- Name: goodbye_feedbacks; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE goodbye_feedbacks (
    id integer NOT NULL,
    user_id integer NOT NULL,
    next_player character varying(255),
    reason character varying(255) NOT NULL,
    comment text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: goodbye_feedbacks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE goodbye_feedbacks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: goodbye_feedbacks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE goodbye_feedbacks_id_seq OWNED BY goodbye_feedbacks.id;


--
-- Name: invoice_items; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE invoice_items (
    id integer NOT NULL,
    type character varying(255),
    invoice_id integer,
    item_type character varying(255),
    item_id integer,
    started_at timestamp without time zone,
    ended_at timestamp without time zone,
    discounted_percentage double precision,
    price integer,
    amount integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    deal_id integer
);


--
-- Name: invoice_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE invoice_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: invoice_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE invoice_items_id_seq OWNED BY invoice_items.id;


--
-- Name: invoices; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE invoices (
    id integer NOT NULL,
    site_id integer,
    reference character varying(255),
    state character varying(255),
    customer_full_name character varying(255),
    customer_email character varying(255),
    customer_country character varying(255),
    customer_company_name character varying(255),
    site_hostname character varying(255),
    amount integer,
    vat_rate double precision,
    vat_amount integer,
    invoice_items_amount integer,
    invoice_items_count integer DEFAULT 0,
    transactions_count integer DEFAULT 0,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    paid_at timestamp without time zone,
    last_failed_at timestamp without time zone,
    renew boolean DEFAULT false,
    balance_deduction_amount integer DEFAULT 0,
    customer_billing_address text
);


--
-- Name: invoices_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE invoices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: invoices_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE invoices_id_seq OWNED BY invoices.id;


--
-- Name: invoices_transactions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE invoices_transactions (
    invoice_id integer,
    transaction_id integer
);


--
-- Name: mail_logs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE mail_logs (
    id integer NOT NULL,
    template_id integer,
    admin_id integer,
    criteria text,
    user_ids text,
    snapshot text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: mail_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE mail_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mail_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE mail_logs_id_seq OWNED BY mail_logs.id;


--
-- Name: mail_templates; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE mail_templates (
    id integer NOT NULL,
    title character varying(255),
    subject character varying(255),
    body text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: mail_templates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE mail_templates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mail_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE mail_templates_id_seq OWNED BY mail_templates.id;


--
-- Name: oauth_tokens; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE oauth_tokens (
    id integer NOT NULL,
    type character varying(20),
    user_id integer,
    client_application_id integer,
    token character varying(40),
    secret character varying(40),
    callback_url character varying(255),
    verifier character varying(20),
    scope character varying(255),
    authorized_at timestamp without time zone,
    invalidated_at timestamp without time zone,
    valid_to timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: oauth_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE oauth_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: oauth_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE oauth_tokens_id_seq OWNED BY oauth_tokens.id;


--
-- Name: plans; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE plans (
    id integer NOT NULL,
    name character varying(255),
    token character varying(255),
    cycle character varying(255),
    video_views integer,
    price integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    support_level integer DEFAULT 0,
    stats_retention_days integer
);


--
-- Name: plans_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE plans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: plans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE plans_id_seq OWNED BY plans.id;


--
-- Name: player_bundle_versions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE player_bundle_versions (
    id integer NOT NULL,
    player_bundle_id integer,
    version character varying(255),
    settings text,
    zip character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: player_bundle_versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE player_bundle_versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: player_bundle_versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE player_bundle_versions_id_seq OWNED BY player_bundle_versions.id;


--
-- Name: player_bundles; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE player_bundles (
    id integer NOT NULL,
    token character varying(255),
    name character varying(255),
    version_tags hstore,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: player_bundles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE player_bundles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: player_bundles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE player_bundles_id_seq OWNED BY player_bundles.id;


--
-- Name: player_bundleships; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE player_bundleships (
    id integer NOT NULL,
    site_id integer,
    player_bundle_id integer,
    version_tag character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: player_bundleships_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE player_bundleships_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: player_bundleships_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE player_bundleships_id_seq OWNED BY player_bundleships.id;


--
-- Name: releases; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE releases (
    id integer NOT NULL,
    token character varying(255),
    date character varying(255),
    zip character varying(255),
    state character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: releases_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE releases_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: releases_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE releases_id_seq OWNED BY releases.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: sites; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE sites (
    id integer NOT NULL,
    user_id integer,
    hostname character varying(255),
    dev_hostnames text,
    token character varying(255),
    license character varying(255),
    loader character varying(255),
    state character varying(255),
    archived_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    player_mode character varying(255) DEFAULT 'stable'::character varying,
    google_rank integer,
    alexa_rank integer,
    path character varying(255),
    wildcard boolean,
    extra_hostnames text,
    plan_id integer,
    pending_plan_id integer,
    next_cycle_plan_id integer,
    cdn_up_to_date boolean DEFAULT false,
    first_paid_plan_started_at timestamp without time zone,
    plan_started_at timestamp without time zone,
    plan_cycle_started_at timestamp without time zone,
    plan_cycle_ended_at timestamp without time zone,
    pending_plan_started_at timestamp without time zone,
    pending_plan_cycle_started_at timestamp without time zone,
    pending_plan_cycle_ended_at timestamp without time zone,
    overusage_notification_sent_at timestamp without time zone,
    first_plan_upgrade_required_alert_sent_at timestamp without time zone,
    refunded_at timestamp without time zone,
    last_30_days_main_video_views integer DEFAULT 0,
    last_30_days_extra_video_views integer DEFAULT 0,
    last_30_days_dev_video_views integer DEFAULT 0,
    trial_started_at timestamp without time zone,
    badged boolean,
    last_30_days_invalid_video_views integer DEFAULT 0,
    last_30_days_embed_video_views integer DEFAULT 0,
    last_30_days_billable_video_views_array text,
    last_30_days_video_tags integer DEFAULT 0,
    first_billable_plays_at timestamp without time zone,
    settings_updated_at timestamp without time zone
);


--
-- Name: sites_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sites_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sites_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE sites_id_seq OWNED BY sites.id;


--
-- Name: taggings; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE taggings (
    id integer NOT NULL,
    tag_id integer,
    taggable_id integer,
    taggable_type character varying(255),
    tagger_id integer,
    tagger_type character varying(255),
    context character varying(128),
    created_at timestamp without time zone
);


--
-- Name: taggings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE taggings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: taggings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE taggings_id_seq OWNED BY taggings.id;


--
-- Name: tags; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tags (
    id integer NOT NULL,
    name character varying(255)
);


--
-- Name: tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tags_id_seq OWNED BY tags.id;


--
-- Name: transactions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE transactions (
    id integer NOT NULL,
    user_id integer,
    order_id character varying(255),
    state character varying(255),
    amount integer,
    error text,
    cc_type character varying(255),
    cc_last_digits character varying(255),
    cc_expire_on date,
    pay_id character varying(255),
    nc_status integer,
    status integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: transactions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE transactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: transactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE transactions_id_seq OWNED BY transactions.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users (
    id integer NOT NULL,
    state character varying(255),
    email character varying(255) DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying(128) DEFAULT ''::character varying NOT NULL,
    password_salt character varying(255) DEFAULT ''::character varying NOT NULL,
    confirmation_token character varying(255),
    confirmed_at timestamp without time zone,
    confirmation_sent_at timestamp without time zone,
    reset_password_token character varying(255),
    remember_token character varying(255),
    remember_created_at timestamp without time zone,
    sign_in_count integer DEFAULT 0,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip character varying(255),
    last_sign_in_ip character varying(255),
    failed_attempts integer DEFAULT 0,
    locked_at timestamp without time zone,
    cc_type character varying(255),
    cc_last_digits character varying(255),
    cc_expire_on date,
    cc_updated_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    invitation_token character varying(60),
    invitation_sent_at timestamp without time zone,
    zendesk_id integer,
    enthusiast_id integer,
    postal_code character varying(255),
    country character varying(255),
    use_personal boolean,
    use_company boolean,
    use_clients boolean,
    company_name character varying(255),
    company_url character varying(255),
    company_job_title character varying(255),
    company_employees character varying(255),
    company_videos_served character varying(255),
    cc_alias character varying(255),
    pending_cc_type character varying(255),
    pending_cc_last_digits character varying(255),
    pending_cc_expire_on date,
    pending_cc_updated_at timestamp without time zone,
    archived_at timestamp without time zone,
    newsletter boolean DEFAULT false,
    last_invoiced_amount integer DEFAULT 0,
    total_invoiced_amount integer DEFAULT 0,
    balance integer DEFAULT 0,
    hidden_notice_ids text,
    name character varying(255),
    billing_name character varying(255),
    billing_address_1 character varying(255),
    billing_address_2 character varying(255),
    billing_postal_code character varying(255),
    billing_city character varying(255),
    billing_region character varying(255),
    billing_country character varying(255),
    last_failed_cc_authorize_at timestamp without time zone,
    last_failed_cc_authorize_status integer,
    last_failed_cc_authorize_error character varying(255),
    referrer_site_token character varying(255),
    reset_password_sent_at timestamp without time zone,
    confirmation_comment text,
    unconfirmed_email character varying(255),
    invitation_accepted_at timestamp without time zone,
    invitation_limit integer,
    invited_by_id integer,
    invited_by_type character varying(255),
    vip boolean DEFAULT false,
    early_access character varying(255) DEFAULT ''::character varying
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: versions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE versions (
    id integer NOT NULL,
    item_type character varying(255) NOT NULL,
    item_id integer NOT NULL,
    event character varying(255) NOT NULL,
    whodunnit character varying(255),
    object text,
    created_at timestamp without time zone,
    admin_id character varying(255),
    ip character varying(255),
    user_agent character varying(255)
);


--
-- Name: versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE versions_id_seq OWNED BY versions.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE admins ALTER COLUMN id SET DEFAULT nextval('admins_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE client_applications ALTER COLUMN id SET DEFAULT nextval('client_applications_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE deal_activations ALTER COLUMN id SET DEFAULT nextval('deal_activations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE deals ALTER COLUMN id SET DEFAULT nextval('deals_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE delayed_jobs ALTER COLUMN id SET DEFAULT nextval('delayed_jobs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE enthusiast_sites ALTER COLUMN id SET DEFAULT nextval('enthusiast_sites_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE enthusiasts ALTER COLUMN id SET DEFAULT nextval('enthusiasts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE goodbye_feedbacks ALTER COLUMN id SET DEFAULT nextval('goodbye_feedbacks_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE invoice_items ALTER COLUMN id SET DEFAULT nextval('invoice_items_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE invoices ALTER COLUMN id SET DEFAULT nextval('invoices_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE mail_logs ALTER COLUMN id SET DEFAULT nextval('mail_logs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE mail_templates ALTER COLUMN id SET DEFAULT nextval('mail_templates_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE oauth_tokens ALTER COLUMN id SET DEFAULT nextval('oauth_tokens_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE plans ALTER COLUMN id SET DEFAULT nextval('plans_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE player_bundle_versions ALTER COLUMN id SET DEFAULT nextval('player_bundle_versions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE player_bundles ALTER COLUMN id SET DEFAULT nextval('player_bundles_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE player_bundleships ALTER COLUMN id SET DEFAULT nextval('player_bundleships_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE releases ALTER COLUMN id SET DEFAULT nextval('releases_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE sites ALTER COLUMN id SET DEFAULT nextval('sites_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE taggings ALTER COLUMN id SET DEFAULT nextval('taggings_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE tags ALTER COLUMN id SET DEFAULT nextval('tags_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE transactions ALTER COLUMN id SET DEFAULT nextval('transactions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE versions ALTER COLUMN id SET DEFAULT nextval('versions_id_seq'::regclass);


--
-- Name: admins_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY admins
    ADD CONSTRAINT admins_pkey PRIMARY KEY (id);


--
-- Name: client_applications_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY client_applications
    ADD CONSTRAINT client_applications_pkey PRIMARY KEY (id);


--
-- Name: deal_activations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY deal_activations
    ADD CONSTRAINT deal_activations_pkey PRIMARY KEY (id);


--
-- Name: deals_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY deals
    ADD CONSTRAINT deals_pkey PRIMARY KEY (id);


--
-- Name: delayed_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY delayed_jobs
    ADD CONSTRAINT delayed_jobs_pkey PRIMARY KEY (id);


--
-- Name: enthusiast_sites_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY enthusiast_sites
    ADD CONSTRAINT enthusiast_sites_pkey PRIMARY KEY (id);


--
-- Name: enthusiasts_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY enthusiasts
    ADD CONSTRAINT enthusiasts_pkey PRIMARY KEY (id);


--
-- Name: goodbye_feedbacks_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY goodbye_feedbacks
    ADD CONSTRAINT goodbye_feedbacks_pkey PRIMARY KEY (id);


--
-- Name: invoice_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY invoice_items
    ADD CONSTRAINT invoice_items_pkey PRIMARY KEY (id);


--
-- Name: invoices_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY invoices
    ADD CONSTRAINT invoices_pkey PRIMARY KEY (id);


--
-- Name: mail_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY mail_logs
    ADD CONSTRAINT mail_logs_pkey PRIMARY KEY (id);


--
-- Name: mail_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY mail_templates
    ADD CONSTRAINT mail_templates_pkey PRIMARY KEY (id);


--
-- Name: oauth_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY oauth_tokens
    ADD CONSTRAINT oauth_tokens_pkey PRIMARY KEY (id);


--
-- Name: plans_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY plans
    ADD CONSTRAINT plans_pkey PRIMARY KEY (id);


--
-- Name: player_bundle_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY player_bundle_versions
    ADD CONSTRAINT player_bundle_versions_pkey PRIMARY KEY (id);


--
-- Name: player_bundles_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY player_bundles
    ADD CONSTRAINT player_bundles_pkey PRIMARY KEY (id);


--
-- Name: player_bundleships_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY player_bundleships
    ADD CONSTRAINT player_bundleships_pkey PRIMARY KEY (id);


--
-- Name: releases_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY releases
    ADD CONSTRAINT releases_pkey PRIMARY KEY (id);


--
-- Name: sites_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sites
    ADD CONSTRAINT sites_pkey PRIMARY KEY (id);


--
-- Name: taggings_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY taggings
    ADD CONSTRAINT taggings_pkey PRIMARY KEY (id);


--
-- Name: tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tags
    ADD CONSTRAINT tags_pkey PRIMARY KEY (id);


--
-- Name: transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT transactions_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY versions
    ADD CONSTRAINT versions_pkey PRIMARY KEY (id);


--
-- Name: delayed_jobs_priority; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX delayed_jobs_priority ON delayed_jobs USING btree (priority, run_at);


--
-- Name: index_admins_on_email; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_admins_on_email ON admins USING btree (email);


--
-- Name: index_admins_on_invitation_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_admins_on_invitation_token ON admins USING btree (invitation_token);


--
-- Name: index_admins_on_reset_password_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_admins_on_reset_password_token ON admins USING btree (reset_password_token);


--
-- Name: index_client_applications_on_key; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_client_applications_on_key ON client_applications USING btree (key);


--
-- Name: index_deal_activations_on_deal_id_and_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_deal_activations_on_deal_id_and_user_id ON deal_activations USING btree (deal_id, user_id);


--
-- Name: index_deals_on_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_deals_on_token ON deals USING btree (token);


--
-- Name: index_enthusiast_sites_on_enthusiast_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_enthusiast_sites_on_enthusiast_id ON enthusiast_sites USING btree (enthusiast_id);


--
-- Name: index_enthusiasts_on_email; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_enthusiasts_on_email ON enthusiasts USING btree (email);


--
-- Name: index_goodbye_feedbacks_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_goodbye_feedbacks_on_user_id ON goodbye_feedbacks USING btree (user_id);


--
-- Name: index_invoice_items_on_deal_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_invoice_items_on_deal_id ON invoice_items USING btree (deal_id);


--
-- Name: index_invoice_items_on_invoice_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_invoice_items_on_invoice_id ON invoice_items USING btree (invoice_id);


--
-- Name: index_invoice_items_on_item_type_and_item_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_invoice_items_on_item_type_and_item_id ON invoice_items USING btree (item_type, item_id);


--
-- Name: index_invoices_on_reference; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_invoices_on_reference ON invoices USING btree (reference);


--
-- Name: index_invoices_on_site_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_invoices_on_site_id ON invoices USING btree (site_id);


--
-- Name: index_mail_logs_on_template_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_mail_logs_on_template_id ON mail_logs USING btree (template_id);


--
-- Name: index_oauth_tokens_on_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_oauth_tokens_on_token ON oauth_tokens USING btree (token);


--
-- Name: index_plans_on_name_and_cycle; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_plans_on_name_and_cycle ON plans USING btree (name, cycle);


--
-- Name: index_plans_on_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_plans_on_token ON plans USING btree (token);


--
-- Name: index_player_bundle_versions_on_player_bundle_id_and_version; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_player_bundle_versions_on_player_bundle_id_and_version ON player_bundle_versions USING btree (player_bundle_id, version);


--
-- Name: index_player_bundles_on_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_player_bundles_on_name ON player_bundles USING btree (name);


--
-- Name: index_player_bundles_on_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_player_bundles_on_token ON player_bundles USING btree (token);


--
-- Name: index_player_bundleships_on_player_bundle_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_player_bundleships_on_player_bundle_id ON player_bundleships USING btree (player_bundle_id);


--
-- Name: index_player_bundleships_on_site_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_player_bundleships_on_site_id ON player_bundleships USING btree (site_id);


--
-- Name: index_releases_on_state; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_releases_on_state ON releases USING btree (state);


--
-- Name: index_sites_on_created_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_sites_on_created_at ON sites USING btree (created_at);


--
-- Name: index_sites_on_hostname; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_sites_on_hostname ON sites USING btree (hostname);


--
-- Name: index_sites_on_last_30_days_dev_video_views; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_sites_on_last_30_days_dev_video_views ON sites USING btree (last_30_days_dev_video_views);


--
-- Name: index_sites_on_last_30_days_embed_video_views; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_sites_on_last_30_days_embed_video_views ON sites USING btree (last_30_days_embed_video_views);


--
-- Name: index_sites_on_last_30_days_extra_video_views; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_sites_on_last_30_days_extra_video_views ON sites USING btree (last_30_days_extra_video_views);


--
-- Name: index_sites_on_last_30_days_invalid_video_views; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_sites_on_last_30_days_invalid_video_views ON sites USING btree (last_30_days_invalid_video_views);


--
-- Name: index_sites_on_last_30_days_main_video_views; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_sites_on_last_30_days_main_video_views ON sites USING btree (last_30_days_main_video_views);


--
-- Name: index_sites_on_plan_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_sites_on_plan_id ON sites USING btree (plan_id);


--
-- Name: index_sites_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_sites_on_user_id ON sites USING btree (user_id);


--
-- Name: index_taggings_on_tag_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_taggings_on_tag_id ON taggings USING btree (tag_id);


--
-- Name: index_taggings_on_taggable_id_and_taggable_type_and_context; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_taggings_on_taggable_id_and_taggable_type_and_context ON taggings USING btree (taggable_id, taggable_type, context);


--
-- Name: index_transactions_on_order_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_transactions_on_order_id ON transactions USING btree (order_id);


--
-- Name: index_users_on_cc_alias; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_cc_alias ON users USING btree (cc_alias);


--
-- Name: index_users_on_confirmation_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_confirmation_token ON users USING btree (confirmation_token);


--
-- Name: index_users_on_created_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_users_on_created_at ON users USING btree (created_at);


--
-- Name: index_users_on_current_sign_in_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_users_on_current_sign_in_at ON users USING btree (current_sign_in_at);


--
-- Name: index_users_on_email_and_archived_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_email_and_archived_at ON users USING btree (email, archived_at);


--
-- Name: index_users_on_last_invoiced_amount; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_users_on_last_invoiced_amount ON users USING btree (last_invoiced_amount);


--
-- Name: index_users_on_referrer_site_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_users_on_referrer_site_token ON users USING btree (referrer_site_token);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON users USING btree (reset_password_token);


--
-- Name: index_users_on_total_invoiced_amount; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_users_on_total_invoiced_amount ON users USING btree (total_invoiced_amount);


--
-- Name: index_versions_on_item_type_and_item_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_versions_on_item_type_and_item_id ON versions USING btree (item_type, item_id);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- PostgreSQL database dump complete
--

INSERT INTO schema_migrations (version) VALUES ('20100510081902');

INSERT INTO schema_migrations (version) VALUES ('20100510151422');

INSERT INTO schema_migrations (version) VALUES ('20100517081010');

INSERT INTO schema_migrations (version) VALUES ('20100517085007');

INSERT INTO schema_migrations (version) VALUES ('20100519125619');

INSERT INTO schema_migrations (version) VALUES ('20100526094453');

INSERT INTO schema_migrations (version) VALUES ('20100601074800');

INSERT INTO schema_migrations (version) VALUES ('20100609101737');

INSERT INTO schema_migrations (version) VALUES ('20100609105116');

INSERT INTO schema_migrations (version) VALUES ('20100609123904');

INSERT INTO schema_migrations (version) VALUES ('20100618083918');

INSERT INTO schema_migrations (version) VALUES ('20100622080554');

INSERT INTO schema_migrations (version) VALUES ('20100625150205');

INSERT INTO schema_migrations (version) VALUES ('20100630153415');

INSERT INTO schema_migrations (version) VALUES ('20100701081248');

INSERT INTO schema_migrations (version) VALUES ('20100701091254');

INSERT INTO schema_migrations (version) VALUES ('20100706142731');

INSERT INTO schema_migrations (version) VALUES ('20100707142429');

INSERT INTO schema_migrations (version) VALUES ('20100707142455');

INSERT INTO schema_migrations (version) VALUES ('20100720092023');

INSERT INTO schema_migrations (version) VALUES ('20100720101348');

INSERT INTO schema_migrations (version) VALUES ('20100722100536');

INSERT INTO schema_migrations (version) VALUES ('20100722155430');

INSERT INTO schema_migrations (version) VALUES ('20100723135123');

INSERT INTO schema_migrations (version) VALUES ('20100810064432');

INSERT INTO schema_migrations (version) VALUES ('20100811101434');

INSERT INTO schema_migrations (version) VALUES ('20100818125357');

INSERT INTO schema_migrations (version) VALUES ('20100826081322');

INSERT INTO schema_migrations (version) VALUES ('20100906131301');

INSERT INTO schema_migrations (version) VALUES ('20100908190804');

INSERT INTO schema_migrations (version) VALUES ('20101004102346');

INSERT INTO schema_migrations (version) VALUES ('20101004143410');

INSERT INTO schema_migrations (version) VALUES ('20101026120935');

INSERT INTO schema_migrations (version) VALUES ('20101026120936');

INSERT INTO schema_migrations (version) VALUES ('20101027140154');

INSERT INTO schema_migrations (version) VALUES ('20101101104735');

INSERT INTO schema_migrations (version) VALUES ('20101101142323');

INSERT INTO schema_migrations (version) VALUES ('20101101145802');

INSERT INTO schema_migrations (version) VALUES ('20110223160948');

INSERT INTO schema_migrations (version) VALUES ('20110405125244');

INSERT INTO schema_migrations (version) VALUES ('20110701131602');

INSERT INTO schema_migrations (version) VALUES ('20110831124847');

INSERT INTO schema_migrations (version) VALUES ('20111007085033');

INSERT INTO schema_migrations (version) VALUES ('20111017074843');

INSERT INTO schema_migrations (version) VALUES ('20111017081014');

INSERT INTO schema_migrations (version) VALUES ('20111101125136');

INSERT INTO schema_migrations (version) VALUES ('20111109102818');

INSERT INTO schema_migrations (version) VALUES ('20111113201857');

INSERT INTO schema_migrations (version) VALUES ('20111120143816');

INSERT INTO schema_migrations (version) VALUES ('20111120195507');

INSERT INTO schema_migrations (version) VALUES ('20111124103434');

INSERT INTO schema_migrations (version) VALUES ('20111125093738');

INSERT INTO schema_migrations (version) VALUES ('20111128142033');

INSERT INTO schema_migrations (version) VALUES ('20111214134523');

INSERT INTO schema_migrations (version) VALUES ('20120127102215');

INSERT INTO schema_migrations (version) VALUES ('20120206144727');

INSERT INTO schema_migrations (version) VALUES ('20120213144210');

INSERT INTO schema_migrations (version) VALUES ('20120216113706');

INSERT INTO schema_migrations (version) VALUES ('20120308114325');

INSERT INTO schema_migrations (version) VALUES ('20120410150900');

INSERT INTO schema_migrations (version) VALUES ('20120424131357');

INSERT INTO schema_migrations (version) VALUES ('20120501130751');

INSERT INTO schema_migrations (version) VALUES ('20120503133139');

INSERT INTO schema_migrations (version) VALUES ('20120508104334');

INSERT INTO schema_migrations (version) VALUES ('20120611162802');

INSERT INTO schema_migrations (version) VALUES ('20120815081953');

INSERT INTO schema_migrations (version) VALUES ('20120815145448');

INSERT INTO schema_migrations (version) VALUES ('20120822113838');

INSERT INTO schema_migrations (version) VALUES ('20120822114051');

INSERT INTO schema_migrations (version) VALUES ('20120822121335');

INSERT INTO schema_migrations (version) VALUES ('20120827130456');

INSERT INTO schema_migrations (version) VALUES ('20120828124519');

INSERT INTO schema_migrations (version) VALUES ('20120828143641');