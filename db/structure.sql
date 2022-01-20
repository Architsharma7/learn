SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: active_admin_comments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_admin_comments (
    id bigint NOT NULL,
    namespace character varying,
    body text,
    resource_type character varying,
    resource_id bigint,
    author_type character varying,
    author_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: active_admin_comments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_admin_comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_admin_comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_admin_comments_id_seq OWNED BY public.active_admin_comments.id;


--
-- Name: activity_pub_followers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.activity_pub_followers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    metadata text NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: admin_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admin_users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    email character varying DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying,
    reset_password_sent_at timestamp without time zone,
    remember_created_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: collection_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.collection_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    collection_id uuid NOT NULL,
    item_id uuid NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: collections; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.collections (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying NOT NULL,
    user_id uuid NOT NULL,
    is_public boolean DEFAULT false NOT NULL,
    description text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: course_invite_codes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.course_invite_codes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code character varying NOT NULL,
    description text,
    course_id uuid NOT NULL,
    max_limit integer DEFAULT 1 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: courses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.courses (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying NOT NULL,
    description text,
    image_url character varying,
    topic_id uuid NOT NULL,
    user_id uuid NOT NULL,
    cost integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    score integer DEFAULT 0,
    final_message text,
    first_assistant_id uuid,
    second_assistant_id uuid,
    invite_msg text
);


--
-- Name: decks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.decks (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying,
    user_id uuid NOT NULL,
    is_public boolean DEFAULT false NOT NULL,
    description character varying,
    image_url character varying,
    tags character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: delayed_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.delayed_jobs (
    id bigint NOT NULL,
    priority integer DEFAULT 0 NOT NULL,
    attempts integer DEFAULT 0 NOT NULL,
    handler text NOT NULL,
    last_error text,
    run_at timestamp without time zone,
    locked_at timestamp without time zone,
    failed_at timestamp without time zone,
    locked_by character varying,
    queue character varying,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone
);


--
-- Name: delayed_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.delayed_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: delayed_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.delayed_jobs_id_seq OWNED BY public.delayed_jobs.id;


--
-- Name: flash_cards; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.flash_cards (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    question text NOT NULL,
    answer text NOT NULL,
    level integer DEFAULT 1 NOT NULL,
    url character varying,
    last_practiced_at timestamp without time zone,
    practice_count integer,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    next_practice_due_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    user_id uuid NOT NULL,
    deck_id uuid NOT NULL
);


--
-- Name: group_members; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.group_members (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    group_id uuid NOT NULL,
    user_id uuid NOT NULL,
    role character varying NOT NULL,
    status character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.groups (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying NOT NULL,
    description text,
    image_url character varying,
    website_url character varying,
    is_public boolean DEFAULT false NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: idea_sets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.idea_sets (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    description text
);


--
-- Name: item_reactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.item_reactions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    kind character varying NOT NULL,
    body text,
    user_id uuid NOT NULL,
    item_id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: item_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.item_types (
    id character varying NOT NULL,
    display_name_plural character varying
);


--
-- Name: items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying NOT NULL,
    item_type_id character varying NOT NULL,
    estimated_time integer,
    time_unit character varying DEFAULT 'minutes'::character varying NOT NULL,
    required_expertise integer,
    idea_set_id uuid NOT NULL,
    user_id uuid NOT NULL,
    year integer,
    image_url character varying,
    inspirational_score numeric(3,2),
    educational_score numeric(3,2),
    challenging_score numeric(3,2),
    entertaining_score numeric(3,2),
    visual_score numeric(3,2),
    interactive_score numeric(3,2),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    level character varying,
    description text,
    metadata json DEFAULT '{}'::json NOT NULL,
    page_count integer,
    goodreads_rating numeric(3,2),
    amazon_rating numeric(3,2),
    isbn character varying,
    isbn13 character varying,
    cost numeric(8,2),
    language character varying,
    overall_score numeric(3,2),
    protected_description text,
    is_approved boolean DEFAULT false NOT NULL
);


--
-- Name: levels; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.levels (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying NOT NULL,
    description text,
    course_id uuid NOT NULL,
    seq integer NOT NULL,
    item_type_id character varying,
    link character varying,
    answer_type character varying NOT NULL,
    answer_prompt text NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: links; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.links (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    url character varying NOT NULL,
    item_id uuid NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    name character varying,
    is_primary boolean,
    embed_tag character varying,
    mimetype character varying,
    has_paywall boolean,
    has_loginwall boolean,
    has_ads boolean
);


--
-- Name: people; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.people (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying NOT NULL,
    description text,
    website character varying,
    email character varying,
    twitter character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    metadata json DEFAULT '{}'::json NOT NULL,
    goodreads character varying,
    image_url character varying,
    kind character varying,
    second_kind character varying,
    wikipedia_url character varying,
    youtube_url character varying
);


--
-- Name: person_idea_sets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.person_idea_sets (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    person_id uuid NOT NULL,
    idea_set_id uuid NOT NULL,
    role character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: recommendations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.recommendations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    idea_set_id uuid NOT NULL,
    metadata text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    item_id uuid,
    person_id uuid,
    url character varying,
    notes text,
    score numeric(3,2),
    user_id uuid
);


--
-- Name: review_reactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.review_reactions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    kind character varying NOT NULL,
    body text,
    user_id uuid NOT NULL,
    review_id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: reviews; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reviews (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    item_id uuid NOT NULL,
    status character varying,
    inspirational_score integer,
    educational_score integer,
    challenging_score integer,
    entertaining_score integer,
    visual_score integer,
    interactive_score integer,
    notes text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    overall_score integer,
    is_posted_on_social_media boolean DEFAULT false,
    private_notes text
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: slack_authorizations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.slack_authorizations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    token json NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: slack_subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.slack_subscriptions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    slack_authorization_id uuid NOT NULL,
    channel_id character varying NOT NULL,
    topic_id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: social_logins; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.social_logins (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    auth0_uid character varying,
    auth0_info json,
    post_reviews boolean DEFAULT true NOT NULL,
    user_id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: topic_activity_pub_followers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.topic_activity_pub_followers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    topic_id uuid NOT NULL,
    metadata text NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: topic_idea_sets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.topic_idea_sets (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    topic_id uuid NOT NULL,
    idea_set_id uuid NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    rating integer
);


--
-- Name: topic_reactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.topic_reactions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    kind character varying NOT NULL,
    body text,
    user_id uuid NOT NULL,
    topic_id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: topic_relations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.topic_relations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    from_id uuid NOT NULL,
    to_id uuid NOT NULL,
    kind character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: topics; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.topics (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying NOT NULL,
    search_index character varying NOT NULL,
    gitter_room character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    display_name character varying,
    user_id uuid,
    parent_id uuid,
    second_parent_id uuid,
    image_url character varying,
    gitter_room_id character varying,
    description text,
    wiki_title character varying,
    gpt_quiz_prompt text,
    gpt_answer_prompt text,
    slack_room_id character varying,
    followers_count integer
);


--
-- Name: user_levels; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_levels (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    course_id uuid NOT NULL,
    level_id uuid NOT NULL,
    answer text,
    status character varying NOT NULL,
    feedback text,
    metadata json,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    invite_code character varying
);


--
-- Name: user_topics; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_topics (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    topic_id uuid NOT NULL,
    action character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: user_user_relations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_user_relations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    from_user_id uuid NOT NULL,
    to_user_id uuid NOT NULL,
    action character varying DEFAULT 'follow'::character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    CONSTRAINT reject_self_reference CHECK ((from_user_id <> to_user_id))
);


--
-- Name: user_vouchers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_vouchers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id bigint NOT NULL,
    voucher_id bigint NOT NULL,
    status character varying NOT NULL,
    expires_at date,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    nickname character varying NOT NULL,
    image_url character varying,
    bio character varying,
    description text,
    score integer DEFAULT 100 NOT NULL,
    role character varying DEFAULT 'regular'::character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    random_fav_topic boolean DEFAULT false NOT NULL,
    random_fav_item_types character varying,
    referrer character varying,
    unsubscribe boolean DEFAULT false NOT NULL,
    has_used_browser_extension boolean DEFAULT false NOT NULL,
    has_used_embed boolean DEFAULT false NOT NULL,
    tiddlywiki_url character varying,
    theme character varying,
    rocketchat_logintoken character varying
);


--
-- Name: vouchers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vouchers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id bigint NOT NULL,
    code character varying NOT NULL,
    max_limit integer,
    payment_ref character varying,
    domain character varying,
    price integer,
    period_days integer,
    internal_description character varying,
    status character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: active_admin_comments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_admin_comments ALTER COLUMN id SET DEFAULT nextval('public.active_admin_comments_id_seq'::regclass);


--
-- Name: delayed_jobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delayed_jobs ALTER COLUMN id SET DEFAULT nextval('public.delayed_jobs_id_seq'::regclass);


--
-- Name: active_admin_comments active_admin_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_admin_comments
    ADD CONSTRAINT active_admin_comments_pkey PRIMARY KEY (id);


--
-- Name: activity_pub_followers activity_pub_followers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_pub_followers
    ADD CONSTRAINT activity_pub_followers_pkey PRIMARY KEY (id);


--
-- Name: admin_users admin_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_users
    ADD CONSTRAINT admin_users_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: collection_items collection_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collection_items
    ADD CONSTRAINT collection_items_pkey PRIMARY KEY (id);


--
-- Name: collections collections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collections
    ADD CONSTRAINT collections_pkey PRIMARY KEY (id);


--
-- Name: course_invite_codes course_invite_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course_invite_codes
    ADD CONSTRAINT course_invite_codes_pkey PRIMARY KEY (id);


--
-- Name: courses courses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.courses
    ADD CONSTRAINT courses_pkey PRIMARY KEY (id);


--
-- Name: decks decks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.decks
    ADD CONSTRAINT decks_pkey PRIMARY KEY (id);


--
-- Name: delayed_jobs delayed_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delayed_jobs
    ADD CONSTRAINT delayed_jobs_pkey PRIMARY KEY (id);


--
-- Name: flash_cards flash_cards_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flash_cards
    ADD CONSTRAINT flash_cards_pkey PRIMARY KEY (id);


--
-- Name: group_members group_members_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_members
    ADD CONSTRAINT group_members_pkey PRIMARY KEY (id);


--
-- Name: groups groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groups
    ADD CONSTRAINT groups_pkey PRIMARY KEY (id);


--
-- Name: idea_sets idea_sets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.idea_sets
    ADD CONSTRAINT idea_sets_pkey PRIMARY KEY (id);


--
-- Name: item_reactions item_reactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.item_reactions
    ADD CONSTRAINT item_reactions_pkey PRIMARY KEY (id);


--
-- Name: item_types item_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.item_types
    ADD CONSTRAINT item_types_pkey PRIMARY KEY (id);


--
-- Name: items items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.items
    ADD CONSTRAINT items_pkey PRIMARY KEY (id);


--
-- Name: levels levels_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.levels
    ADD CONSTRAINT levels_pkey PRIMARY KEY (id);


--
-- Name: links links_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.links
    ADD CONSTRAINT links_pkey PRIMARY KEY (id);


--
-- Name: people people_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.people
    ADD CONSTRAINT people_pkey PRIMARY KEY (id);


--
-- Name: person_idea_sets person_idea_sets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.person_idea_sets
    ADD CONSTRAINT person_idea_sets_pkey PRIMARY KEY (id);


--
-- Name: recommendations recommendations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recommendations
    ADD CONSTRAINT recommendations_pkey PRIMARY KEY (id);


--
-- Name: review_reactions review_reactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.review_reactions
    ADD CONSTRAINT review_reactions_pkey PRIMARY KEY (id);


--
-- Name: reviews reviews_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT reviews_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: slack_authorizations slack_authorizations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.slack_authorizations
    ADD CONSTRAINT slack_authorizations_pkey PRIMARY KEY (id);


--
-- Name: slack_subscriptions slack_subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.slack_subscriptions
    ADD CONSTRAINT slack_subscriptions_pkey PRIMARY KEY (id);


--
-- Name: social_logins social_logins_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.social_logins
    ADD CONSTRAINT social_logins_pkey PRIMARY KEY (id);


--
-- Name: topic_activity_pub_followers topic_activity_pub_followers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.topic_activity_pub_followers
    ADD CONSTRAINT topic_activity_pub_followers_pkey PRIMARY KEY (id);


--
-- Name: topic_idea_sets topic_idea_sets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.topic_idea_sets
    ADD CONSTRAINT topic_idea_sets_pkey PRIMARY KEY (id);


--
-- Name: topic_reactions topic_reactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.topic_reactions
    ADD CONSTRAINT topic_reactions_pkey PRIMARY KEY (id);


--
-- Name: topic_relations topic_relations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.topic_relations
    ADD CONSTRAINT topic_relations_pkey PRIMARY KEY (id);


--
-- Name: topics topics_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.topics
    ADD CONSTRAINT topics_pkey PRIMARY KEY (id);


--
-- Name: user_levels user_levels_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_levels
    ADD CONSTRAINT user_levels_pkey PRIMARY KEY (id);


--
-- Name: user_topics user_topics_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_topics
    ADD CONSTRAINT user_topics_pkey PRIMARY KEY (id);


--
-- Name: user_user_relations user_user_relations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_user_relations
    ADD CONSTRAINT user_user_relations_pkey PRIMARY KEY (id);


--
-- Name: user_vouchers user_vouchers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_vouchers
    ADD CONSTRAINT user_vouchers_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: vouchers vouchers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vouchers
    ADD CONSTRAINT vouchers_pkey PRIMARY KEY (id);


--
-- Name: delayed_jobs_priority; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX delayed_jobs_priority ON public.delayed_jobs USING btree (priority, run_at);


--
-- Name: index_active_admin_comments_on_author; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_active_admin_comments_on_author ON public.active_admin_comments USING btree (author_type, author_id);


--
-- Name: index_active_admin_comments_on_namespace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_active_admin_comments_on_namespace ON public.active_admin_comments USING btree (namespace);


--
-- Name: index_active_admin_comments_on_resource; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_active_admin_comments_on_resource ON public.active_admin_comments USING btree (resource_type, resource_id);


--
-- Name: index_activity_pub_followers_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_pub_followers_on_user_id ON public.activity_pub_followers USING btree (user_id);


--
-- Name: index_admin_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_admin_users_on_email ON public.admin_users USING btree (email);


--
-- Name: index_admin_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_admin_users_on_reset_password_token ON public.admin_users USING btree (reset_password_token);


--
-- Name: index_collection_items_on_collection_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collection_items_on_collection_id ON public.collection_items USING btree (collection_id);


--
-- Name: index_collection_items_on_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collection_items_on_item_id ON public.collection_items USING btree (item_id);


--
-- Name: index_collections_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collections_on_user_id ON public.collections USING btree (user_id);


--
-- Name: index_course_invite_codes_on_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_course_invite_codes_on_course_id ON public.course_invite_codes USING btree (course_id);


--
-- Name: index_course_invite_codes_on_course_id_and_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_course_invite_codes_on_course_id_and_code ON public.course_invite_codes USING btree (course_id, code);


--
-- Name: index_courses_on_first_assistant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_courses_on_first_assistant_id ON public.courses USING btree (first_assistant_id);


--
-- Name: index_courses_on_second_assistant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_courses_on_second_assistant_id ON public.courses USING btree (second_assistant_id);


--
-- Name: index_courses_on_topic_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_courses_on_topic_id ON public.courses USING btree (topic_id);


--
-- Name: index_courses_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_courses_on_user_id ON public.courses USING btree (user_id);


--
-- Name: index_decks_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_decks_on_user_id ON public.decks USING btree (user_id);


--
-- Name: index_decks_on_user_id_and_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_decks_on_user_id_and_name ON public.decks USING btree (user_id, name);


--
-- Name: index_flash_cards_on_deck_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_flash_cards_on_deck_id ON public.flash_cards USING btree (deck_id);


--
-- Name: index_group_members_on_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_group_members_on_group_id ON public.group_members USING btree (group_id);


--
-- Name: index_group_members_on_group_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_group_members_on_group_id_and_user_id ON public.group_members USING btree (group_id, user_id);


--
-- Name: index_group_members_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_group_members_on_user_id ON public.group_members USING btree (user_id);


--
-- Name: index_item_reactions_on_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_item_reactions_on_item_id ON public.item_reactions USING btree (item_id);


--
-- Name: index_item_reactions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_item_reactions_on_user_id ON public.item_reactions USING btree (user_id);


--
-- Name: index_items_on_idea_set_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_items_on_idea_set_id ON public.items USING btree (idea_set_id);


--
-- Name: index_items_on_item_type_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_items_on_item_type_id ON public.items USING btree (item_type_id);


--
-- Name: index_items_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_items_on_user_id ON public.items USING btree (user_id);


--
-- Name: index_levels_on_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_levels_on_course_id ON public.levels USING btree (course_id);


--
-- Name: index_levels_on_item_type_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_levels_on_item_type_id ON public.levels USING btree (item_type_id);


--
-- Name: index_links_on_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_links_on_item_id ON public.links USING btree (item_id);


--
-- Name: index_links_on_url; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_links_on_url ON public.links USING btree (url);


--
-- Name: index_people_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_people_on_name ON public.people USING btree (name);


--
-- Name: index_person_idea_sets_on_idea_set_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_person_idea_sets_on_idea_set_id ON public.person_idea_sets USING btree (idea_set_id);


--
-- Name: index_person_idea_sets_on_person_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_person_idea_sets_on_person_id ON public.person_idea_sets USING btree (person_id);


--
-- Name: index_recommendations_on_idea_set_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_recommendations_on_idea_set_id ON public.recommendations USING btree (idea_set_id);


--
-- Name: index_recommendations_on_item_id_and_idea_set_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_recommendations_on_item_id_and_idea_set_id ON public.recommendations USING btree (item_id, idea_set_id) WHERE (item_id IS NOT NULL);


--
-- Name: index_recommendations_on_person_id_and_idea_set_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_recommendations_on_person_id_and_idea_set_id ON public.recommendations USING btree (person_id, idea_set_id) WHERE (person_id IS NOT NULL);


--
-- Name: index_review_reactions_on_review_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_review_reactions_on_review_id ON public.review_reactions USING btree (review_id);


--
-- Name: index_review_reactions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_review_reactions_on_user_id ON public.review_reactions USING btree (user_id);


--
-- Name: index_reviews_on_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reviews_on_item_id ON public.reviews USING btree (item_id);


--
-- Name: index_reviews_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reviews_on_user_id ON public.reviews USING btree (user_id);


--
-- Name: index_reviews_on_user_id_and_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_reviews_on_user_id_and_item_id ON public.reviews USING btree (user_id, item_id);


--
-- Name: index_slack_subscriptions_on_slack_authorization_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_slack_subscriptions_on_slack_authorization_id ON public.slack_subscriptions USING btree (slack_authorization_id);


--
-- Name: index_slack_subscriptions_on_topic_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_slack_subscriptions_on_topic_id ON public.slack_subscriptions USING btree (topic_id);


--
-- Name: index_social_logins_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_social_logins_on_user_id ON public.social_logins USING btree (user_id);


--
-- Name: index_topic_activity_pub_followers_on_topic_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_topic_activity_pub_followers_on_topic_id ON public.topic_activity_pub_followers USING btree (topic_id);


--
-- Name: index_topic_idea_sets_on_idea_set_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_topic_idea_sets_on_idea_set_id ON public.topic_idea_sets USING btree (idea_set_id);


--
-- Name: index_topic_idea_sets_on_topic_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_topic_idea_sets_on_topic_id ON public.topic_idea_sets USING btree (topic_id);


--
-- Name: index_topic_idea_sets_on_topic_id_and_idea_set_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_topic_idea_sets_on_topic_id_and_idea_set_id ON public.topic_idea_sets USING btree (topic_id, idea_set_id);


--
-- Name: index_topic_reactions_on_topic_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_topic_reactions_on_topic_id ON public.topic_reactions USING btree (topic_id);


--
-- Name: index_topic_reactions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_topic_reactions_on_user_id ON public.topic_reactions USING btree (user_id);


--
-- Name: index_topic_relations_on_from_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_topic_relations_on_from_id ON public.topic_relations USING btree (from_id);


--
-- Name: index_topic_relations_on_to_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_topic_relations_on_to_id ON public.topic_relations USING btree (to_id);


--
-- Name: index_topics_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_topics_on_name ON public.topics USING btree (name);


--
-- Name: index_topics_on_parent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_topics_on_parent_id ON public.topics USING btree (parent_id);


--
-- Name: index_topics_on_second_parent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_topics_on_second_parent_id ON public.topics USING btree (second_parent_id);


--
-- Name: index_topics_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_topics_on_user_id ON public.topics USING btree (user_id);


--
-- Name: index_user_levels_on_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_levels_on_course_id ON public.user_levels USING btree (course_id);


--
-- Name: index_user_levels_on_level_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_levels_on_level_id ON public.user_levels USING btree (level_id);


--
-- Name: index_user_levels_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_levels_on_user_id ON public.user_levels USING btree (user_id);


--
-- Name: index_user_topics_on_topic_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_topics_on_topic_id ON public.user_topics USING btree (topic_id);


--
-- Name: index_user_topics_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_topics_on_user_id ON public.user_topics USING btree (user_id);


--
-- Name: index_user_user_relations_on_from_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_user_relations_on_from_user_id ON public.user_user_relations USING btree (from_user_id);


--
-- Name: index_user_user_relations_on_to_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_user_relations_on_to_user_id ON public.user_user_relations USING btree (to_user_id);


--
-- Name: index_user_vouchers_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_vouchers_on_user_id ON public.user_vouchers USING btree (user_id);


--
-- Name: index_user_vouchers_on_voucher_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_vouchers_on_voucher_id ON public.user_vouchers USING btree (voucher_id);


--
-- Name: index_vouchers_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_vouchers_on_user_id ON public.vouchers USING btree (user_id);


--
-- Name: trgm_items_name_indx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trgm_items_name_indx ON public.items USING gist (name public.gist_trgm_ops);


--
-- Name: uniq_from_to_action; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uniq_from_to_action ON public.user_user_relations USING btree (from_user_id, to_user_id, action);


--
-- Name: uniq_user_topic_action; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uniq_user_topic_action ON public.user_topics USING btree (user_id, topic_id, action);


--
-- Name: user_topics fk_rails_0aa5b25f82; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_topics
    ADD CONSTRAINT fk_rails_0aa5b25f82 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: slack_subscriptions fk_rails_0eeea316fa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.slack_subscriptions
    ADD CONSTRAINT fk_rails_0eeea316fa FOREIGN KEY (slack_authorization_id) REFERENCES public.slack_authorizations(id);


--
-- Name: user_user_relations fk_rails_10bcd883e4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_user_relations
    ADD CONSTRAINT fk_rails_10bcd883e4 FOREIGN KEY (from_user_id) REFERENCES public.users(id);


--
-- Name: topic_activity_pub_followers fk_rails_14e820a7ac; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.topic_activity_pub_followers
    ADD CONSTRAINT fk_rails_14e820a7ac FOREIGN KEY (topic_id) REFERENCES public.topics(id);


--
-- Name: item_reactions fk_rails_199c5d286b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.item_reactions
    ADD CONSTRAINT fk_rails_199c5d286b FOREIGN KEY (item_id) REFERENCES public.items(id);


--
-- Name: reviews fk_rails_1b37fb5a2a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT fk_rails_1b37fb5a2a FOREIGN KEY (item_id) REFERENCES public.items(id);


--
-- Name: flash_cards fk_rails_1c774d0179; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flash_cards
    ADD CONSTRAINT fk_rails_1c774d0179 FOREIGN KEY (deck_id) REFERENCES public.decks(id);


--
-- Name: review_reactions fk_rails_1e6125f51a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.review_reactions
    ADD CONSTRAINT fk_rails_1e6125f51a FOREIGN KEY (review_id) REFERENCES public.reviews(id);


--
-- Name: collection_items fk_rails_29c02f6872; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collection_items
    ADD CONSTRAINT fk_rails_29c02f6872 FOREIGN KEY (item_id) REFERENCES public.items(id);


--
-- Name: topics fk_rails_2dbda122e8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.topics
    ADD CONSTRAINT fk_rails_2dbda122e8 FOREIGN KEY (second_parent_id) REFERENCES public.topics(id);


--
-- Name: item_reactions fk_rails_3604c6fade; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.item_reactions
    ADD CONSTRAINT fk_rails_3604c6fade FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: activity_pub_followers fk_rails_3ce6f9a7a2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_pub_followers
    ADD CONSTRAINT fk_rails_3ce6f9a7a2 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: topic_reactions fk_rails_42cd7106b8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.topic_reactions
    ADD CONSTRAINT fk_rails_42cd7106b8 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: topic_relations fk_rails_4e9299d5db; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.topic_relations
    ADD CONSTRAINT fk_rails_4e9299d5db FOREIGN KEY (to_id) REFERENCES public.topics(id);


--
-- Name: topic_idea_sets fk_rails_4fb9cd9cdf; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.topic_idea_sets
    ADD CONSTRAINT fk_rails_4fb9cd9cdf FOREIGN KEY (topic_id) REFERENCES public.topics(id);


--
-- Name: recommendations fk_rails_5057f7d09a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recommendations
    ADD CONSTRAINT fk_rails_5057f7d09a FOREIGN KEY (idea_set_id) REFERENCES public.idea_sets(id);


--
-- Name: decks fk_rails_5d31349cbe; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.decks
    ADD CONSTRAINT fk_rails_5d31349cbe FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: topics fk_rails_5f3c091f12; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.topics
    ADD CONSTRAINT fk_rails_5f3c091f12 FOREIGN KEY (parent_id) REFERENCES public.topics(id);


--
-- Name: courses fk_rails_65e51188f9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.courses
    ADD CONSTRAINT fk_rails_65e51188f9 FOREIGN KEY (second_assistant_id) REFERENCES public.users(id);


--
-- Name: review_reactions fk_rails_6975d6d5df; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.review_reactions
    ADD CONSTRAINT fk_rails_6975d6d5df FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: items fk_rails_6bed0f90a5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.items
    ADD CONSTRAINT fk_rails_6bed0f90a5 FOREIGN KEY (item_type_id) REFERENCES public.item_types(id);


--
-- Name: reviews fk_rails_74a66bd6c5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT fk_rails_74a66bd6c5 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: courses fk_rails_74cf90f09f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.courses
    ADD CONSTRAINT fk_rails_74cf90f09f FOREIGN KEY (topic_id) REFERENCES public.topics(id);


--
-- Name: topics fk_rails_7b812cfb44; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.topics
    ADD CONSTRAINT fk_rails_7b812cfb44 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: topic_idea_sets fk_rails_853a6f5036; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.topic_idea_sets
    ADD CONSTRAINT fk_rails_853a6f5036 FOREIGN KEY (idea_set_id) REFERENCES public.idea_sets(id);


--
-- Name: user_levels fk_rails_957708fd26; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_levels
    ADD CONSTRAINT fk_rails_957708fd26 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: collections fk_rails_9b33697360; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collections
    ADD CONSTRAINT fk_rails_9b33697360 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: collection_items fk_rails_b1a778644b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collection_items
    ADD CONSTRAINT fk_rails_b1a778644b FOREIGN KEY (collection_id) REFERENCES public.collections(id);


--
-- Name: courses fk_rails_b3c61f05ef; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.courses
    ADD CONSTRAINT fk_rails_b3c61f05ef FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: group_members fk_rails_bb66f6bca8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_members
    ADD CONSTRAINT fk_rails_bb66f6bca8 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: user_topics fk_rails_bfe29ea272; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_topics
    ADD CONSTRAINT fk_rails_bfe29ea272 FOREIGN KEY (topic_id) REFERENCES public.topics(id);


--
-- Name: person_idea_sets fk_rails_c3b7c63f2d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.person_idea_sets
    ADD CONSTRAINT fk_rails_c3b7c63f2d FOREIGN KEY (idea_set_id) REFERENCES public.idea_sets(id);


--
-- Name: user_levels fk_rails_cdb3e7b24f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_levels
    ADD CONSTRAINT fk_rails_cdb3e7b24f FOREIGN KEY (level_id) REFERENCES public.levels(id);


--
-- Name: levels fk_rails_d223b78719; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.levels
    ADD CONSTRAINT fk_rails_d223b78719 FOREIGN KEY (item_type_id) REFERENCES public.item_types(id);


--
-- Name: items fk_rails_d4b6334db2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.items
    ADD CONSTRAINT fk_rails_d4b6334db2 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: user_user_relations fk_rails_d52301166a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_user_relations
    ADD CONSTRAINT fk_rails_d52301166a FOREIGN KEY (to_user_id) REFERENCES public.users(id);


--
-- Name: items fk_rails_d85b4d9a08; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.items
    ADD CONSTRAINT fk_rails_d85b4d9a08 FOREIGN KEY (idea_set_id) REFERENCES public.idea_sets(id);


--
-- Name: person_idea_sets fk_rails_dc3ce95beb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.person_idea_sets
    ADD CONSTRAINT fk_rails_dc3ce95beb FOREIGN KEY (person_id) REFERENCES public.people(id);


--
-- Name: links fk_rails_e1bb872bea; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.links
    ADD CONSTRAINT fk_rails_e1bb872bea FOREIGN KEY (item_id) REFERENCES public.items(id);


--
-- Name: levels fk_rails_e397b0035d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.levels
    ADD CONSTRAINT fk_rails_e397b0035d FOREIGN KEY (course_id) REFERENCES public.courses(id);


--
-- Name: group_members fk_rails_e9fdb70ec5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_members
    ADD CONSTRAINT fk_rails_e9fdb70ec5 FOREIGN KEY (group_id) REFERENCES public.groups(id);


--
-- Name: topic_reactions fk_rails_ef81f07a8f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.topic_reactions
    ADD CONSTRAINT fk_rails_ef81f07a8f FOREIGN KEY (topic_id) REFERENCES public.topics(id);


--
-- Name: slack_subscriptions fk_rails_f22957c2b3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.slack_subscriptions
    ADD CONSTRAINT fk_rails_f22957c2b3 FOREIGN KEY (topic_id) REFERENCES public.topics(id);


--
-- Name: topic_relations fk_rails_f2d3454ee0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.topic_relations
    ADD CONSTRAINT fk_rails_f2d3454ee0 FOREIGN KEY (from_id) REFERENCES public.topics(id);


--
-- Name: social_logins fk_rails_f53abcfb16; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.social_logins
    ADD CONSTRAINT fk_rails_f53abcfb16 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: course_invite_codes fk_rails_f62e25d07c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course_invite_codes
    ADD CONSTRAINT fk_rails_f62e25d07c FOREIGN KEY (course_id) REFERENCES public.courses(id);


--
-- Name: flash_cards fk_rails_f949b3ea79; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flash_cards
    ADD CONSTRAINT fk_rails_f949b3ea79 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: user_levels fk_rails_f98c61ac53; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_levels
    ADD CONSTRAINT fk_rails_f98c61ac53 FOREIGN KEY (course_id) REFERENCES public.courses(id);


--
-- Name: courses fk_rails_fbdda12dea; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.courses
    ADD CONSTRAINT fk_rails_fbdda12dea FOREIGN KEY (first_assistant_id) REFERENCES public.users(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20190318163043'),
('20190319060555'),
('20190323161504'),
('20190323161545'),
('20190323161740'),
('20190323161823'),
('20190323164142'),
('20190323164144'),
('20190323181309'),
('20190519045414'),
('20190519061036'),
('20190604140829'),
('20190610164206'),
('20190616171344'),
('20190625190258'),
('20190625194234'),
('20190705003038'),
('20190706110136'),
('20190706175347'),
('20190714025449'),
('20190717185003'),
('20190725101714'),
('20190725173959'),
('20190807061505'),
('20190807165023'),
('20190821060649'),
('20190917115933'),
('20191021073641'),
('20191101144409'),
('20191101172456'),
('20191105105946'),
('20191108051151'),
('20191114042350'),
('20200112192301'),
('20200212205915'),
('20200213173853'),
('20200222193438'),
('20200223073231'),
('20200305015533'),
('20200330145935'),
('20200409195801'),
('20200411150429'),
('20200412035642'),
('20200412061911'),
('20200414183335'),
('20200416185108'),
('20200419091150'),
('20200513012642'),
('20200517043602'),
('20200527001352'),
('20200530085910'),
('20200617194825'),
('20200623155710'),
('20200624062708'),
('20200630171020'),
('20200708190856'),
('20200710170939'),
('20200711173541'),
('20200716071412'),
('20200721183427'),
('20200721201658'),
('20200723051447'),
('20200730185439'),
('20200824210734'),
('20200824230523'),
('20200922144058'),
('20200930190125'),
('20201010231135'),
('20201013025845'),
('20201013025846'),
('20201018233116'),
('20201019010226'),
('20201230145346'),
('20210116203058'),
('20210123134411'),
('20210320143641'),
('20210320144041'),
('20210320144914'),
('20210321095807'),
('20210321142504'),
('20210422124328');


