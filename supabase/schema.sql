-- ==============================================================================
-- PASO 1: ESQUEMA DE BASE DE DATOS - "GASTRONOMÍA A LA CHILENA"
-- ==============================================================================

-- Habilitar extensión pgcrypto para gen_random_uuid() si no está habilitada por defecto
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==============================================================================
-- 1. TABLA: profiles (Extensión de auth.users)
-- ==============================================================================
CREATE TABLE public.profiles (
    id uuid REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    role text DEFAULT 'user'::text CHECK (role IN ('user', 'admin')),
    display_name text,
    avatar_url text,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Perfiles visibles para todos." ON public.profiles
    FOR SELECT USING (true);

CREATE POLICY "Usuarios pueden actualizar su propio perfil." ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

-- Trigger para crear perfil automáticamente al registrarse en auth.users
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, display_name, avatar_url)
  VALUES (
    new.id, 
    COALESCE(new.raw_user_meta_data->>'full_name', 'Usuario Chileno'), 
    new.raw_user_meta_data->>'avatar_url'
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- ==============================================================================
-- 2. TABLA: banned_words (Palabras prohibidas para moderación automatizada)
-- ==============================================================================
CREATE TABLE public.banned_words (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    word text UNIQUE NOT NULL,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.banned_words ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Palabras prohibidas visibles para todos" ON public.banned_words
    FOR SELECT USING (true);

CREATE POLICY "Solo admins modifican palabras prohibidas" ON public.banned_words
    FOR ALL USING (
        EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- ==============================================================================
-- 3. TABLA: recipes (Recetas de la app)
-- ==============================================================================
CREATE TABLE public.recipes (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    author_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    title text NOT NULL,
    description text,
    ingredients text[] NOT NULL,
    instructions text[] NOT NULL,
    prep_time_minutes int,
    servings int,
    category text CHECK (category IN ('General', 'Comida caliente', 'Comida fría', 'Repostería')),
    media_urls text[], -- Almacena URLs de fotos y videos
    edit_count int DEFAULT 0 NOT NULL,
    is_hidden boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.recipes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Recetas públicas si no están ocultas" ON public.recipes
    FOR SELECT USING (is_hidden = false OR auth.uid() IN (SELECT id FROM profiles WHERE role = 'admin'));

CREATE POLICY "Usuarios insertan recetas propias" ON public.recipes
    FOR INSERT WITH CHECK (auth.uid() = author_id);

CREATE POLICY "Usuarios actualizan recetas propias" ON public.recipes
    FOR UPDATE USING (auth.uid() = author_id OR auth.uid() IN (SELECT id FROM profiles WHERE role = 'admin'));

CREATE POLICY "Usuarios eliminan recetas propias" ON public.recipes
    FOR DELETE USING (auth.uid() = author_id OR auth.uid() IN (SELECT id FROM profiles WHERE role = 'admin'));

-- ==============================================================================
-- 4. TABLA: comments (Comentarios en recetas)
-- ==============================================================================
CREATE TABLE public.comments (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    recipe_id uuid REFERENCES public.recipes(id) ON DELETE CASCADE NOT NULL,
    author_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    content text NOT NULL,
    media_urls text[], -- Máx 2 fotos (validado en frontend)
    is_hidden boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Comentarios públicos si no están ocultos" ON public.comments
    FOR SELECT USING (is_hidden = false OR auth.uid() IN (SELECT id FROM profiles WHERE role = 'admin'));

CREATE POLICY "Usuarios insertan comentarios propios" ON public.comments
    FOR INSERT WITH CHECK (auth.uid() = author_id);

CREATE POLICY "Usuarios actualizan comentarios propios" ON public.comments
    FOR UPDATE USING (auth.uid() = author_id OR auth.uid() IN (SELECT id FROM profiles WHERE role = 'admin'));

CREATE POLICY "Usuarios eliminan comentarios propios" ON public.comments
    FOR DELETE USING (auth.uid() = author_id OR auth.uid() IN (SELECT id FROM profiles WHERE role = 'admin'));

-- ==============================================================================
-- 5. TABLA: ratings (Calificaciones 1-5 estrellas)
-- ==============================================================================
CREATE TABLE public.ratings (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    recipe_id uuid REFERENCES public.recipes(id) ON DELETE CASCADE NOT NULL,
    user_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    score int CHECK (score >= 1 AND score <= 5) NOT NULL,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(recipe_id, user_id)
);

ALTER TABLE public.ratings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Calificaciones públicas" ON public.ratings
    FOR SELECT USING (true);

CREATE POLICY "Usuarios insertan calificaciones propias" ON public.ratings
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Usuarios actualizan calificaciones propias" ON public.ratings
    FOR UPDATE USING (auth.uid() = user_id);

-- ==============================================================================
-- 6. TABLA: reports (Moderación Comunitaria)
-- ==============================================================================
CREATE TABLE public.reports (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    reporter_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    entity_type text CHECK (entity_type IN ('recipe', 'comment')) NOT NULL,
    entity_id uuid NOT NULL,
    reason text,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(reporter_id, entity_type, entity_id) -- Un reporte único por usuario/entidad
);

ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Solo admins leen reportes" ON public.reports
    FOR SELECT USING (auth.uid() IN (SELECT id FROM profiles WHERE role = 'admin'));

CREATE POLICY "Usuarios insertan reportes" ON public.reports
    FOR INSERT WITH CHECK (auth.uid() = reporter_id);

-- ==============================================================================
-- 7. TABLA: favorite_recipes (Recetas favoritas de usuarios)
-- ==============================================================================
CREATE TABLE public.favorite_recipes (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    recipe_id uuid REFERENCES public.recipes(id) ON DELETE CASCADE NOT NULL,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(user_id, recipe_id)
);

ALTER TABLE public.favorite_recipes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Usuarios leen sus favoritos" ON public.favorite_recipes
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Usuarios insertan sus favoritos" ON public.favorite_recipes
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Usuarios eliminan sus favoritos" ON public.favorite_recipes
    FOR DELETE USING (auth.uid() = user_id);

-- ==============================================================================
-- 8. FUNCIONES Y TRIGGERS (LÓGICA DE NEGOCIO Y MODERACIÓN)
-- ==============================================================================

-- A) Filtro de Palabras Prohibidas
CREATE OR REPLACE FUNCTION check_banned_words() RETURNS trigger AS $$
DECLARE
    word_record RECORD;
BEGIN
    FOR word_record IN SELECT word FROM public.banned_words LOOP
        IF (TG_TABLE_NAME = 'recipes') THEN
            IF (NEW.title ILIKE '%' || word_record.word || '%' OR 
                NEW.description ILIKE '%' || word_record.word || '%' OR 
                array_to_string(NEW.ingredients, ' ') ILIKE '%' || word_record.word || '%' OR
                array_to_string(NEW.instructions, ' ') ILIKE '%' || word_record.word || '%') THEN
                RAISE EXCEPTION 'Contenido no permitido. Contiene palabra prohibida: %', word_record.word;
            END IF;
        ELSIF (TG_TABLE_NAME = 'comments') THEN
            IF (NEW.content ILIKE '%' || word_record.word || '%') THEN
                RAISE EXCEPTION 'Contenido no permitido. Contiene palabra prohibida: %', word_record.word;
            END IF;
        END IF;
    END LOOP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_banned_words_recipes
    BEFORE INSERT OR UPDATE ON public.recipes
    FOR EACH ROW EXECUTE PROCEDURE check_banned_words();

CREATE TRIGGER check_banned_words_comments
    BEFORE INSERT OR UPDATE ON public.comments
    FOR EACH ROW EXECUTE PROCEDURE check_banned_words();

-- B) Límite de Publicaciones Diarias
CREATE OR REPLACE FUNCTION check_daily_limits() RETURNS trigger AS $$
DECLARE
    daily_count int;
BEGIN
    IF (TG_TABLE_NAME = 'recipes') THEN
        SELECT count(*) INTO daily_count FROM public.recipes 
        WHERE author_id = NEW.author_id 
        AND created_at >= (now() - interval '1 day');
        IF daily_count >= 3 THEN
            RAISE EXCEPTION 'Límite diario de 3 recetas alcanzado.';
        END IF;
    ELSIF (TG_TABLE_NAME = 'comments') THEN
        SELECT count(*) INTO daily_count FROM public.comments 
        WHERE author_id = NEW.author_id 
        AND created_at >= (now() - interval '1 day');
        IF daily_count >= 5 THEN
            RAISE EXCEPTION 'Límite diario de 5 comentarios alcanzado.';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_daily_limit_recipes
    BEFORE INSERT ON public.recipes
    FOR EACH ROW EXECUTE PROCEDURE check_daily_limits();

CREATE TRIGGER check_daily_limit_comments
    BEFORE INSERT ON public.comments
    FOR EACH ROW EXECUTE PROCEDURE check_daily_limits();

-- C) Auto-ocultar con 3 reportes únicos
CREATE OR REPLACE FUNCTION auto_hide_on_reports() RETURNS trigger AS $$
DECLARE
    report_count int;
BEGIN
    SELECT count(*) INTO report_count FROM public.reports 
    WHERE entity_type = NEW.entity_type AND entity_id = NEW.entity_id;
    
    IF report_count >= 3 THEN
        IF NEW.entity_type = 'recipe' THEN
            UPDATE public.recipes SET is_hidden = true WHERE id = NEW.entity_id;
        ELSIF NEW.entity_type = 'comment' THEN
            UPDATE public.comments SET is_hidden = true WHERE id = NEW.entity_id;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER auto_hide_entity_on_report
    AFTER INSERT ON public.reports
    FOR EACH ROW EXECUTE PROCEDURE auto_hide_on_reports();

-- D) Límite de 3 ediciones para recetas
CREATE OR REPLACE FUNCTION check_recipe_edits() RETURNS trigger AS $$
BEGIN
    -- Solo aplicar el límite si el autor es quien actualiza (no administradores ocultando)
    IF (auth.uid() = OLD.author_id) THEN
        IF OLD.edit_count >= 3 THEN
            RAISE EXCEPTION 'Límite máximo de 3 ediciones alcanzado.';
        END IF;
        NEW.edit_count = OLD.edit_count + 1;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_edit_limit_recipes
    BEFORE UPDATE ON public.recipes
    FOR EACH ROW EXECUTE PROCEDURE check_recipe_edits();

-- ==============================================================================
-- 9. VISTAS MATERIALIZADAS PARA RANKINGS
-- ==============================================================================

-- Vista de Rankings Globales/Combinados
CREATE MATERIALIZED VIEW public.mv_rankings AS
SELECT 
    r.id AS recipe_id,
    r.title,
    r.author_id,
    COALESCE(avg(ra.score), 0) AS avg_score,
    count(DISTINCT ra.id) AS ratings_count,
    count(DISTINCT c.id) AS comments_count,
    (COALESCE(avg(ra.score), 0) * 0.7 + (count(DISTINCT c.id) * 0.3)) AS combined_score
FROM public.recipes r
LEFT JOIN public.ratings ra ON r.id = ra.recipe_id
LEFT JOIN public.comments c ON r.id = c.recipe_id AND c.is_hidden = false
WHERE r.is_hidden = false
GROUP BY r.id;

-- Función para refrescar las vistas (puede ser llamada por un cron o RPC)
CREATE OR REPLACE FUNCTION refresh_all_rankings()
RETURNS void AS $$
BEGIN
  REFRESH MATERIALIZED VIEW public.mv_rankings;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
