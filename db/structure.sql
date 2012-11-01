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
-- Name: addon_plans; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE addon_plans (
    id integer NOT NULL,
    addon_id integer NOT NULL,
    name character varying(255) NOT NULL,
    price integer NOT NULL,
    availability character varying(255) NOT NULL,
    required_stage character varying(255) DEFAULT 'stable'::character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    public_at timestamp without time zone
);


--
-- Name: addon_plans_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE addon_plans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: addon_plans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE addon_plans_id_seq OWNED BY addon_plans.id;


--
-- Name: addons; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE addons (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    design_dependent boolean DEFAULT true NOT NULL,
    parent_addon_id integer,
    kind character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: addons_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE addons_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: addons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE addons_id_seq OWNED BY addons.id;


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
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
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
-- Name: app_component_versions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE app_component_versions (
    id integer NOT NULL,
    app_component_id integer,
    version character varying(255),
    zip character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    dependencies hstore
);


--
-- Name: app_component_versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE app_component_versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: app_component_versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE app_component_versions_id_seq OWNED BY app_component_versions.id;


--
-- Name: app_components; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE app_components (
    id integer NOT NULL,
    token character varying(255),
    name character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: app_components_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE app_components_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: app_components_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE app_components_id_seq OWNED BY app_components.id;


--
-- Name: app_designs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE app_designs (
    id integer NOT NULL,
    app_component_id integer NOT NULL,
    skin_token character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    price integer NOT NULL,
    availability character varying(255) NOT NULL,
    required_stage character varying(255) DEFAULT 'stable'::character varying NOT NULL,
    public_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: app_designs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE app_designs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: app_designs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE app_designs_id_seq OWNED BY app_designs.id;


--
-- Name: app_plugins; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE app_plugins (
    id integer NOT NULL,
    addon_id integer NOT NULL,
    app_design_id integer,
    app_component_id integer NOT NULL,
    token character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    condition text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: app_plugins_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE app_plugins_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: app_plugins_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE app_plugins_id_seq OWNED BY app_plugins.id;


--
-- Name: app_settings_templates; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE app_settings_templates (
    id integer NOT NULL,
    addon_plan_id integer NOT NULL,
    app_plugin_id integer,
    editable boolean DEFAULT false,
    template text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: app_settings_templates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE app_settings_templates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: app_settings_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE app_settings_templates_id_seq OWNED BY app_settings_templates.id;


--
-- Name: billable_item_activities; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE billable_item_activities (
    id integer NOT NULL,
    site_id integer NOT NULL,
    item_type character varying(255) NOT NULL,
    item_id integer NOT NULL,
    state character varying(255) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: billable_item_activities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE billable_item_activities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: billable_item_activities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE billable_item_activities_id_seq OWNED BY billable_item_activities.id;


--
-- Name: billable_items; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE billable_items (
    id integer NOT NULL,
    site_id integer NOT NULL,
    item_type character varying(255) NOT NULL,
    item_id integer NOT NULL,
    state character varying(255) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: billable_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE billable_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: billable_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE billable_items_id_seq OWNED BY billable_items.id;


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
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
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
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
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
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
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
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
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
-- Name: feedbacks; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE feedbacks (
    id integer NOT NULL,
    user_id integer NOT NULL,
    next_player character varying(255),
    reason character varying(255) NOT NULL,
    comment text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    kind character varying(255)
);


--
-- Name: feedbacks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE feedbacks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: feedbacks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE feedbacks_id_seq OWNED BY feedbacks.id;


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
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
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
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
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
-- Name: kits; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE kits (
    id integer NOT NULL,
    site_id integer NOT NULL,
    app_design_id integer NOT NULL,
    name character varying(255) DEFAULT NULL::character varying NOT NULL,
    settings text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    identifier character varying(255)
);


--
-- Name: kits_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE kits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: kits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE kits_id_seq OWNED BY kits.id;


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
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
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
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
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
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
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
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
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
-- Name: releases; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE releases (
    id integer NOT NULL,
    token character varying(255),
    date character varying(255),
    zip character varying(255),
    state character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
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
    state character varying(255),
    archived_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    accessible_stage character varying(255) DEFAULT 'beta'::character varying,
    google_rank integer,
    alexa_rank integer,
    path character varying(255),
    wildcard boolean,
    extra_hostnames text,
    plan_id integer,
    pending_plan_id integer,
    next_cycle_plan_id integer,
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
    settings_updated_at timestamp without time zone,
    loaders_updated_at timestamp without time zone,
    default_kit_id integer
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
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
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
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
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
    early_access text
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

ALTER TABLE ONLY addon_plans ALTER COLUMN id SET DEFAULT nextval('addon_plans_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY addons ALTER COLUMN id SET DEFAULT nextval('addons_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY admins ALTER COLUMN id SET DEFAULT nextval('admins_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY app_component_versions ALTER COLUMN id SET DEFAULT nextval('app_component_versions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY app_components ALTER COLUMN id SET DEFAULT nextval('app_components_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY app_designs ALTER COLUMN id SET DEFAULT nextval('app_designs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY app_plugins ALTER COLUMN id SET DEFAULT nextval('app_plugins_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY app_settings_templates ALTER COLUMN id SET DEFAULT nextval('app_settings_templates_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY billable_item_activities ALTER COLUMN id SET DEFAULT nextval('billable_item_activities_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY billable_items ALTER COLUMN id SET DEFAULT nextval('billable_items_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY client_applications ALTER COLUMN id SET DEFAULT nextval('client_applications_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY deal_activations ALTER COLUMN id SET DEFAULT nextval('deal_activations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY deals ALTER COLUMN id SET DEFAULT nextval('deals_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY delayed_jobs ALTER COLUMN id SET DEFAULT nextval('delayed_jobs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY enthusiast_sites ALTER COLUMN id SET DEFAULT nextval('enthusiast_sites_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY enthusiasts ALTER COLUMN id SET DEFAULT nextval('enthusiasts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY feedbacks ALTER COLUMN id SET DEFAULT nextval('feedbacks_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY invoice_items ALTER COLUMN id SET DEFAULT nextval('invoice_items_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY invoices ALTER COLUMN id SET DEFAULT nextval('invoices_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY kits ALTER COLUMN id SET DEFAULT nextval('kits_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY mail_logs ALTER COLUMN id SET DEFAULT nextval('mail_logs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY mail_templates ALTER COLUMN id SET DEFAULT nextval('mail_templates_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY oauth_tokens ALTER COLUMN id SET DEFAULT nextval('oauth_tokens_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY plans ALTER COLUMN id SET DEFAULT nextval('plans_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY releases ALTER COLUMN id SET DEFAULT nextval('releases_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY sites ALTER COLUMN id SET DEFAULT nextval('sites_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY taggings ALTER COLUMN id SET DEFAULT nextval('taggings_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tags ALTER COLUMN id SET DEFAULT nextval('tags_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY transactions ALTER COLUMN id SET DEFAULT nextval('transactions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY versions ALTER COLUMN id SET DEFAULT nextval('versions_id_seq'::regclass);


--
-- Name: addon_plans_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY addon_plans
    ADD CONSTRAINT addon_plans_pkey PRIMARY KEY (id);


--
-- Name: addons_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY addons
    ADD CONSTRAINT addons_pkey PRIMARY KEY (id);


--
-- Name: admins_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY admins
    ADD CONSTRAINT admins_pkey PRIMARY KEY (id);


--
-- Name: app_designs_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY app_designs
    ADD CONSTRAINT app_designs_pkey PRIMARY KEY (id);


--
-- Name: app_plugins_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY app_plugins
    ADD CONSTRAINT app_plugins_pkey PRIMARY KEY (id);


--
-- Name: app_settings_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY app_settings_templates
    ADD CONSTRAINT app_settings_templates_pkey PRIMARY KEY (id);


--
-- Name: billable_item_activities_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY billable_item_activities
    ADD CONSTRAINT billable_item_activities_pkey PRIMARY KEY (id);


--
-- Name: billable_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY billable_items
    ADD CONSTRAINT billable_items_pkey PRIMARY KEY (id);


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

ALTER TABLE ONLY feedbacks
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
-- Name: kits_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY kits
    ADD CONSTRAINT kits_pkey PRIMARY KEY (id);


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

ALTER TABLE ONLY app_component_versions
    ADD CONSTRAINT player_bundle_versions_pkey PRIMARY KEY (id);


--
-- Name: player_bundles_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY app_components
    ADD CONSTRAINT player_bundles_pkey PRIMARY KEY (id);


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
-- Name: index_addon_plans_on_addon_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_addon_plans_on_addon_id ON addon_plans USING btree (addon_id);


--
-- Name: index_addon_plans_on_addon_id_and_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_addon_plans_on_addon_id_and_name ON addon_plans USING btree (addon_id, name);


--
-- Name: index_addons_on_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_addons_on_name ON addons USING btree (name);


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
-- Name: index_app_designs_on_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_app_designs_on_name ON app_designs USING btree (name);


--
-- Name: index_app_designs_on_skin_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_app_designs_on_skin_token ON app_designs USING btree (skin_token);


--
-- Name: index_app_plugins_on_app_design_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_app_plugins_on_app_design_id ON app_plugins USING btree (app_design_id);


--
-- Name: index_app_plugins_on_app_design_id_and_addon_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_app_plugins_on_app_design_id_and_addon_id ON app_plugins USING btree (app_design_id, addon_id);


--
-- Name: index_app_settings_templates_on_addon_plan_id_and_app_plugin_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_app_settings_templates_on_addon_plan_id_and_app_plugin_id ON app_settings_templates USING btree (addon_plan_id, app_plugin_id);


--
-- Name: index_billable_item_activities_on_item_type_and_item_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_billable_item_activities_on_item_type_and_item_id ON billable_item_activities USING btree (item_type, item_id);


--
-- Name: index_billable_item_activities_on_site_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_billable_item_activities_on_site_id ON billable_item_activities USING btree (site_id);


--
-- Name: index_billable_items_on_item_type_and_item_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_billable_items_on_item_type_and_item_id ON billable_items USING btree (item_type, item_id);


--
-- Name: index_billable_items_on_item_type_and_item_id_and_site_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_billable_items_on_item_type_and_item_id_and_site_id ON billable_items USING btree (item_type, item_id, site_id);


--
-- Name: index_billable_items_on_site_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_billable_items_on_site_id ON billable_items USING btree (site_id);


--
-- Name: index_client_applications_on_key; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_client_applications_on_key ON client_applications USING btree (key);


--
-- Name: index_component_versions_on_component_id_and_version; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_component_versions_on_component_id_and_version ON app_component_versions USING btree (app_component_id, version);


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
-- Name: index_kits_on_app_design_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_kits_on_app_design_id ON kits USING btree (app_design_id);


--
-- Name: index_kits_on_site_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_kits_on_site_id ON kits USING btree (site_id);


--
-- Name: index_kits_on_site_id_and_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_kits_on_site_id_and_name ON kits USING btree (site_id, name);


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
-- Name: index_player_components_on_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_player_components_on_name ON app_components USING btree (name);


--
-- Name: index_player_components_on_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_player_components_on_token ON app_components USING btree (token);


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

INSERT INTO schema_migrations (version) VALUES ('20100720092023');

INSERT INTO schema_migrations (version) VALUES ('20100720101348');

INSERT INTO schema_migrations (version) VALUES ('20100722100536');

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

INSERT INTO schema_migrations (version) VALUES ('20120830134535');

INSERT INTO schema_migrations (version) VALUES ('20120830142633');

INSERT INTO schema_migrations (version) VALUES ('20120830144913');

INSERT INTO schema_migrations (version) VALUES ('20120904100844');

INSERT INTO schema_migrations (version) VALUES ('20120919094721');

INSERT INTO schema_migrations (version) VALUES ('20120919140602');

INSERT INTO schema_migrations (version) VALUES ('20120924140456');

INSERT INTO schema_migrations (version) VALUES ('20120924141140');

INSERT INTO schema_migrations (version) VALUES ('20121001125756');

INSERT INTO schema_migrations (version) VALUES ('20121004141903');

INSERT INTO schema_migrations (version) VALUES ('20121011095931');

INSERT INTO schema_migrations (version) VALUES ('20121031120524');

INSERT INTO schema_migrations (version) VALUES ('20121101092429');

INSERT INTO schema_migrations (version) VALUES ('20121101103815');