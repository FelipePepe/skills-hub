# Matriz de Riesgo — EU AI Act

## Riesgo Inaceptable (Prohibido)

| Práctica | Ejemplo de código | Estado |
|----------|------------------|--------|
| Reconocimiento de emociones en trabajo/educación | `detect_emotions(input_image)` | Prohibido |
| Clasificación biométrica inferente | `classify_race(biometric_data)` | Prohibido |
| Puntuación social por IA | `score_citizen(profile)` | Prohibido |
| Scraping facial masivo | `scrape_faces_from_web()` | Prohibido |
| Identificación biométrica remota en tiempo real | `realtime_facial_recognition(cctv_feed)` | Prohibido (excepciones limitadas) |
| Manipulación subliminal | `manipulate_subconsciously(prompt)` | Prohibido |
| Explotación de vulnerabilidades | `exploit_vulnerability(age, disability)` | Prohibido |
| Inferencia de crímenes | `predict_crime(profile)` | Prohibido |

**Acción**: Rechazar la implementación. Explicar al usuario por qué es prohibida.

## Alto Riesgo (Anexo III)

| Categoría | Ejemplo | Obligaciones clave |
|-----------|---------|-------------------|
| Biométría identitaria | `identify_person(face_image)` | CE marking, registro, documentación |
| Biometría remota | `facial_id_camera()` | CE marking, logging, supervisión |
| Infraestructura crítica | `power_grid_optimization(ML)` | Risk management, data governance |
| Educación | `student_assessment_AI(model)` | Accuracy, robustness, human oversight |
| Empleo/RRHH | `resume_scoring_AI(cv_data)` | No discriminación, transparencia |
| Crédito/Finanzas | `credit_score_model(X)` | Explicabilidad, auditabilidad |
| Justicia | `legal_risk_predictor(cases)` | Validación humana, documentación |
| Migración/asilo | `immigration_risk_AI(applicant)` | CE marking, registro EU database |
| Democracia | `voter_manipulation_AI(data)` | Transparencia, marcado de contenido |

## Alto Riesgo (Anexo I — General)

| Tipo | Ejemplo | Obligaciones |
|------|---------|-------------|
| Modelos GPAI general | `chatgpt_api.call(prompt)` | Docs, copyright, training summary |
| GPAI con riesgo sistémico | `model trained >10^25 FLOPS` | Red teaming, evaluación,incidentes |

## Riesgo Limitado (Transparencia)

| Categoría | Ejemplo | Obligación |
|-----------|---------|-----------|
| Chatbots | `chatbot.respond(user_msg)` | Informar al usuario que usa IA |
| Generación de contenido | `generate_image(prompt)` | Marcado de contenido sintético |
| Deepfakes | `deepfake_replace(face)` | Disclosure visible y distinguible |
| Emotion recognition (no laboral) | `emotion_detect_photo(img)` | Informar a las personas expuestas |

## Riesgo Mínimo / Sin Riesgo

| Ejemplo | Obligación |
|---------|-----------|
| Filter spam | Ninguna |
| Recommendation engine (sin datos sensibles) | Ninguna |
| Game AI | Ninguna |
| Code completion (no genAI) | Ninguna |

**Acción**: Opcionalmente sugerir buenas prácticas voluntarias.
